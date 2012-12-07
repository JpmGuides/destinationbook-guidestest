# encoding: utf-8
require 'nokogiri'

class ExportGuides
  class Guide
    attr_accessor :id, :s3_path, :zip_data, :generation, :nb_files
    TITLES_XPATH = './h1|./h2|./h3|./h4|./h5|./h6|./h7|./h8|./h9|./h10'
    MAX_IMAGE_SIZE = {:width => 640, :height => nil}
    MAX_THUMBNAIL_SIZE = {:width => 100, :height => 100}

    def initialize(id, s3_path, zip_data = nil)
      @id = id
      @s3_path = s3_path
      @zip_data = zip_data
      @nb_files = 1
    end

    def generate
      export
      save
    end

    def export_images(thumbnails)
      images = []

      @zip_data.each do |entry|
        if entry.file?
          type = entry.to_s.split('.').last.downcase
          root = entry.to_s.split('/').first

          if IMAGE_FILE.include?(type) && root == 'images'
            @nb_files += 1

            if thumbnails.include?(entry.to_s)
              size = MAX_THUMBNAIL_SIZE
            else
              size = MAX_IMAGE_SIZE
            end

            ext = File.extname(entry.to_s)
            ext.slice!(0)
            image = ExportGuides::Image.new(File.basename(entry.to_s, '.*'), @zip_data.read(entry), @id, {:extension => ext, :width => size[:width], :height => size[:height]})
            
            images << {:path => entry.to_s, :url => image.save }
          else
            if type == 'svg' && root == 'images'
              image = ExportGuides::Image.new(File.basename(entry.to_s, '.*'), @zip_data.read(entry), @id, {:extension => ext})
              images << {:path => entry.to_s, :url => image.save }
            end
          end

        end
      end

      images
    end

    def export_maps(guide_html)
      maps = []

      maps_article = guide_html.xpath('//*[@id="maps"]').first

      if maps_article
        maps_article.xpath('./content/article').each do |child_html|
          title = child_html.xpath('./h2').first.text
          path = child_html.xpath('./img').first['src']

          @nb_files += 1
          map = ExportGuides::Image.new(File.basename(path, '.*'), @zip_data.read(path), @id, {:extension => 'svg', :type => 'maps'})
          maps << {:title => title, :path => path, :url => map.save}
        end
        maps_article.remove
      end

      maps
    end

    def export

      current_guide = {}
      thumbnails = []

      File.delete("#{Rails.root}/tmp/#{@id}.html") if File.exists?("#{Rails.root}/tmp/#{@id}.html")

      begin
        @zip_data.extract('phone.html', "#{Rails.root}/tmp/#{@id}.html")
      rescue
        @zip_data.extract('guide.html', "#{Rails.root}/tmp/#{@id}.html")
      end

      file = File.open("#{Rails.root}/tmp/#{@id}.html", "r") 
      guide_text = file.read.force_encoding("UTF-8")
      guide_text.gsub!("\xEF\xBB\xBF".force_encoding("UTF-8"), '')

      guide = Nokogiri::HTML(guide_text)
      guide.encoding = 'UTF-8'

      guide = guide.xpath('./html/body')

      maps = export_maps(guide)

      current_guide[:id] = @id

      if image = guide.xpath('./content/h1/img').first
        current_guide[:titleImage] = image['src']
        thumbnails << image['src']
        image.remove
      end

      if description = guide.xpath('./content/h1').first['title']
        current_guide[:description] = description
      end

      current_guide[:title] = guide.xpath('./content/h1').first.inner_html
      guide.xpath('./content/h1').remove

      if image = guide.xpath('./content/img').first
        current_guide[:headerImageLegend] = image['title'] if image['title']
        current_guide[:headerImage]  = image['src']
        image.remove
      end

      current_guide[:children] = []
      guide.xpath('./content/article').each do |child_html|
        result = export_children(child_html)

        next if result.nil?

        current_guide[:children] << result.first
        thumbnails << result.last
      end
      current_guide[:children].compact!

      current_guide[:images] = export_images(thumbnails)
      current_guide[:maps] = maps

      current_guide[:content] = guide.xpath('./content').inner_html if guide.xpath('./content').inner_html.present?      

      @generation = current_guide
    end

    def export_children(child_html)
      child = {}
      child_thumbnails = []

      # If title does'nt exist, return nil to not add child
      return nil if child_html.xpath(TITLES_XPATH).first.nil?

      # Children
      child[:children] = []
      child_html.xpath('./content/article').each do |next_child_html|
        result = export_children(next_child_html)

        next if result.nil?

        child[:children] << result.first
        child_thumbnails << result.last
      end
      child_html.xpath('./content').first.try(:remove)

      # Header & Title
      title_html = child_html.xpath(TITLES_XPATH).first

      if image_html = title_html.xpath('./img').first
        child[:titleImage] = image_html['src']
        child_thumbnails << image_html['src']
        image_html.remove
      end

      if description = title_html['title']
        child[:description] = description
      end

      child[:title] = title_html.inner_html
      
      if image_html = title_html.xpath('./following-sibling::*[1][self::img]').first
        child[:headerImageLegend] = image_html['title'] if image_html['title']
        child[:headerImage] = image_html['src'] 
        image_html.remove
      end

      title_html.remove

      child_html.xpath('./img').each do |image|
        image.before("<div class='guides-content-image'></div>")
        image_wraper = image.xpath('preceding-sibling::*[1]').first
        image_wraper << image

        if image['title']
          image.after('<span class="legend"></span>')
          image_wraper.xpath('./span').first.content = image['title']
        end

      end
    
      # Content
      child[:content] = child_html.inner_html if child_html.inner_html.present?

      # remove content before return child
      child_html.remove
      [child, child_thumbnails]
    end

    def save

      file = ExportGuides.aws_bucket_directory.files.create(
        'key'                => "#{ENV['GUIDE_PATH']}/#{@id}/guide.json",
        'body'               => ActiveSupport::Gzip.compress("Ext.data.JsonP.callback(#{@generation.to_json})"),
        'content_type'       => 'application/javascript',
        'content_encoding'   => 'gzip',
        'x-amz-meta-nb-file' => @nb_files
      )

      Rails.cache.write("last_modified_#{self.id}",  ExportGuides.aws_bucket_directory.files.head(self.s3_path).last_modified.to_datetime.to_i)
      Rails.cache.delete("on_error_#{self.id}")
      true
    end

  end
end