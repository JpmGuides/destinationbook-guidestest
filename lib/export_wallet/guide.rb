# encoding: utf-8
require 'nokogiri'

class ExportWallet
  class Guide

    attr_accessor :id, :path, :zip_data

    TITLES_XPATH = './h1|./h2|./h3|./h4|./h5|./h6|./h7|./h8|./h9|./h10'
    MAX_IMAGE_SIZE = {:width => 640, :height => nil}
    MAX_THUMBNAIL_SIZE = {:width => 100, :height => 100}


    def initialize(id, path, zip_data = nil)
      @id = id
      @path = path
      @zip_data = zip_data
      @nb_files = 1
      @maps_tiled = []
      @maps_json_content_tiled = []
      @images = []
    end

    ##############
    # attributes #
    ##############

    def generated_path
      File.join(Settings.path.guides_generated, @id)
    end

    def generated_file_path
      File.join(generated_path, 'guide.zip')
    end

    def zip_tempfile_path
      "#{Rails.root}/tmp/tiled_#{@id}_#{Process.pid}_#{Time.now.to_i}.zip"
    end

    def cache_key
      "export_guide_#{@id}"
    end

    ###############
    # api methods #
    ###############

    def self.get(guide_id)
      file_meta = Rails.cache.read("export_guide_#{guide_id}")
      if file_meta.nil?
        if File.exists?("#{Settings.path.guides_generated}/#{guide_id}/guide.zip")
          guide = ExportWallet::Guide.new(guide_id, "#{Settings.path.guides_generated}/#{guide_id}.zip")
          guide.cache!
          file_meta = get(guide_id)
        else
          file_meta = nil
        end
      end

      file_meta
    end

    def cache!
      if File.exists?(generated_file_path)
        guide = File.open(generated_file_path)
        Rails.cache.write(cache_key, {size: guide.size,  generated_at: guide.mtime})
      else
        Rails.cache.delete(cache_key)
      end
    end

    ######################
    # generation methods #
    ######################

    def generate
      export
      save
    end

    def export_images(thumbnails)
      images_json_content = []

      @zip_data.each do |entry|
        if entry.file?
          type = entry.to_s.split('.').last.downcase
          root = entry.to_s.split('/').first

          if IMAGE_FILE.include?(type) && root == 'images'
            size = MAX_IMAGE_SIZE
            ext = File.extname(entry.to_s)
            ext.slice!(0)

            image = ExportGuides::Image.new(File.basename(entry.to_s, '.*'), @zip_data.read(entry), @id, {:extension => ext, :width => size[:width], :height => size[:height]})

            @images << {:path => entry.to_s, :data => image.process(size[:width], size[:height])}
            images_json_content << {:path => entry.to_s}
          elsif type == 'svg' && root == 'images'
            @images << {:path => entry.to_s, :data => @zip_data.read(entry)}
            images_json_content << {:path => entry.to_s}
          end
        end
      end

      thumbnails.each do |thumb|
        real_thumb_name = thumb.split('.').first + '__thumb.' + thumb.split('.').last

        size = MAX_THUMBNAIL_SIZE
        ext = File.extname(thumb)
        ext.slice!(0)

        image = ExportGuides::Image.new(File.basename(real_thumb_name, '.*'), @zip_data.read(thumb), @id, {:extension => ext, :width => size[:width], :height => size[:height]})

        @images << {:path => real_thumb_name, :data => image.process(size[:width], size[:height]) }
        images_json_content << {:path => real_thumb_name}
      end

      images_json_content
    end

    def export_maps(guide_html)
      maps_json_content = []

      maps_article = guide_html.xpath('//*[@id="maps"]').first

      if maps_article
        maps_article.xpath('./content/article').each do |child_html|
          title = child_html.xpath('./h2').first.text
          description = child_html.xpath('./h2').first['title']
          tile = child_html.xpath('./div').first
          anchor = child_html.xpath('./h2').first['data-link-anchor']

          path_tiled = /(maps\/.[^\/]+)/.match(tile['data-map-url'])[0]
          map_tiled_files = []

          @zip_data.each do |entry|
            root = entry.to_s.split('/').first

            if root == 'maps' && entry.to_s.include?(path_tiled) && File.extname(entry.to_s).present? && entry.to_s.last != '/'
              begin
                map_tiled_files << {path: entry.to_s, data: @zip_data.read(entry)}
              rescue
                raise "missing map files : #{entry}"
              end
            end
          end

          if !map_tiled_files.empty?
            @maps_json_content_tiled << {
              title: title,
              description: description,
              path: path_tiled,
              url: tile['data-map-url'],
              width: tile['data-map-width'],
              height: tile['data-map-height'],
              tileSize: tile['data-map-tilesize'],
              minScale: tile['data-map-minscale'],
              maxScale: tile['data-map-maxscale'],
              maxX: tile['data-map-maxx'],
              maxY: tile['data-map-maxy'],
              minX: tile['data-map-minx'],
              minY: tile['data-map-miny'],
              filters: tile['data-map-filters'],
              locateMe: tile['data-map-locateme'],
              linkAnchors: [anchor]
            }
            @maps_tiled << {title: title, path: path_tiled, files: map_tiled_files}
          end
        end

        maps_article.remove
      end

      maps_json_content
    end

    def export_title_image
      ExportWallet.instance.directory.files.create(
      'key'                   => "guides/icons/#{@id}.jpg",
      'body'                  => @zip_data.read("#{@id}.jpg"),
      'content_type'          => 'image/jpeg',
      )

      true
    rescue
      true
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

      export_maps(guide)

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

      chapter_type = child_html.xpath('.').first['id']
      child[:index] = true if chapter_type == 'index'
      child[:poi] = true if chapter_type == 'poi'
      child[:copyright] = true if chapter_type == 'copyright'

      # target
      target = child_html.xpath('.').first['data-link-target']
      child[:linkTarget] = target
      child[:link] = {target: target, options: {}}

      anchors = child_html.css('[data-link-anchor]').map { |anchor| anchor['data-link-anchor'] }
      child[:linkAnchors] = anchors if !anchors.empty?

      marker_geo = target = child_html.xpath('.').first['data-link-mark-geo']
      child[:link][:options] = {markGeo: marker_geo}

      target_options = child_html.xpath('.').first.attributes.select {|k,v| k.include?("data-link-target-option")}
      target_options.each do |key, value|
        export_key = key.gsub('data-link-target-option-', '').gsub('-', '_').camelize(:lower)
        child[:link][:options][export_key.to_sym] = value
      end

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

      child[:type] = title_html['data-type']
      child[:group] = title_html['group']
      child[:sort] = title_html['data-sort']
      child[:listIcon] = title_html['data-list-icon']

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

      contextual_links = child_html.xpath('./aside').first
      if contextual_links
        links = []
        contextual_links.xpath('./a').each do |link|
          options = {type: link['data-link-options-type']}
          options[:markGeo] = link['data-link-options-mark-geo'] if link['data-link-options-mark-geo']
          options[:icon] = link['data-link-options-icon'] if link['data-link-options-icon']
          options[:fill] = link['data-link-options-fill'] if link['data-link-options-fill']
          options[:stroke] = link['data-link-options-stroke'] if link['data-link-options-stroke']
          options[:strokeWidth] = link['data-link-options-stroke-width'] if link['data-link-options-stroke-width']


          texts = []
          link.xpath('./p').each do |text_node|
            text = {text: text_node.inner_html}
            text[:x] = text_node['data-x']
            text[:y] = text_node['data-y']
            text[:stroke] = text_node['data-stroke'] if text_node['data-stroke']
            text[:fill] = text_node['data-fill'] if text_node['data-fill']

            texts << text
          end

          links << {target: link['data-link-target'], options: options, text: texts}
        end
        child[:contextualLinks] = links

        contextual_links.remove
      end
      # Content
      child[:content] = child_html.inner_html if child_html.inner_html.present?

      # remove content before return child
      child_html.remove
      [child, child_thumbnails]
    end

    def save
      File.delete(zip_tempfile_path) if File.exists?(zip_tempfile_path)

      FileUtils.mkdir_p(generated_path) if !File.exists?(generated_path)

      Zip::File.open(generated_file_path, Zip::File::CREATE) do |zip|
        zip.mkdir('images')
        @images.each do |image|
          zip.get_output_stream(image[:path]) { |f| f.puts image[:data] }
        end

        zip.mkdir('maps')
        maps_to_save.each do |map|
          map[:files].each do |file|
            zip.get_output_stream(file[:path]) { |f| f.puts file[:data] }
          end
        end

        zip.get_output_stream('guide.json') { |f| f.puts json_to_save }
      end

      FileUtils.chmod(0755, generated_file_path)

      Rails.cache.write("last_modified_#{self.id}",  File.mtime(path))
      Rails.cache.delete("on_error_#{self.id}")
      true
    ensure
      cache!
    end

    def maps_to_save
      @maps_tiled
    end

    def json_to_save
      @generation.merge({maps: @maps_json_content_tiled}).to_json
    end
  end
end
