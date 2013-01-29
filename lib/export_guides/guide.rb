# encoding: utf-8
require 'nokogiri'

class ExportGuides
  class Guide

    attr_accessor :id, :path, :zip_data, :generation

    TITLES_XPATH = './h1|./h2|./h3|./h4|./h5|./h6|./h7|./h8|./h9|./h10'
    MAX_IMAGE_SIZE = {:width => 640, :height => nil}
    MAX_THUMBNAIL_SIZE = {:width => 100, :height => 100}


    def initialize(id, path, zip_data = nil)
      @id = id
      @path = path
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

            size = MAX_IMAGE_SIZE

            ext = File.extname(entry.to_s)
            ext.slice!(0)
            image = ExportGuides::Image.new(File.basename(entry.to_s, '.*'), @zip_data.read(entry), @id, {:extension => ext, :width => size[:width], :height => size[:height]})
            
            image_data = image.save
            images << {:path => entry.to_s, :url => image_data[0], :size => image_data[1] }
          else
            if type == 'svg' && root == 'images'
              image = ExportGuides::Image.new(File.basename(entry.to_s, '.*'), @zip_data.read(entry), @id, {:extension => ext})

              image_data = image.save
              images << {:path => entry.to_s, :url => image_data[0], :size => image_data[1] }
            end
          end

        end
      end

      thumbnails.each do |thumb|

        real_thumb_name = thumb.split('.').first + '__thumb.' + thumb.split('.').last

        size = MAX_THUMBNAIL_SIZE

        ext = File.extname(thumb)
        ext.slice!(0)
        image = ExportGuides::Image.new(File.basename(real_thumb_name, '.*'), @zip_data.read(thumb), @id, {:extension => ext, :width => size[:width], :height => size[:height]})
        
        image_data = image.save
        images << {:path => real_thumb_name, :url => image_data[0], :size => image_data[1] }
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

          map = ExportGuides::Image.new(File.basename(path, '.*'), @zip_data.read(path), @id, {:extension => 'svg', :type => 'maps'})

          map_data = map.save
          maps << {:title => title, :path => path, :url => map_data[0], :size => map_data[1] }
        end
        maps_article.remove
      end

      maps
    end

    def export

      current_guide = {}
      thumbnails = []

      FileUtils.mkdir_p("#{Rails.root}/tmp") if !File.exists?("#{Rails.root}/tmp")

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
        image_path = image['src']
        current_guide[:titleImage] = image_path.split('.').first + '__thumb.' + image_path.split('.').last
        thumbnails << image_path
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
      thumbnails.flatten!

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
        image_path = image_html['src']
        child[:titleImage] = image_path.split('.').first + '__thumb.' + image_path.split('.').last
        child_thumbnails << image_path
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
      path = "#{Settings.path.guides_generated}/#{id}"

      FileUtils.mkdir_p(path) if !File.exists?(path)

      local_file = File.open("#{path}/guide.json", 'wb+')
      local_file.write(@generation.to_json)
      local_file.close

      Rails.cache.write("last_modified_#{self.id}",  File.mtime(path))
      Rails.cache.delete("on_error_#{self.id}")
      true
    end

  end
end