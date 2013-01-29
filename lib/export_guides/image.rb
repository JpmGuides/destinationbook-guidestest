# encoding: utf-8
require 'RMagick'

class ExportGuides
  class Image
    attr_accessor :name, :data, :guide_id, :options

    def initialize (name, data, guide_id, options)
      @name = name
      @data = data
      @guide_id = guide_id
      @options = options
    end

    def process(width, height)
      img = Magick::Image.from_blob(@data).first

      img.resize_to_fit!(width, height)
      file = img.to_blob
      img.destroy!

      file
    end

    def save
      options = {
        :type       => 'images',
        :extensions => 'jpg',
        :key        => nil,
        :pub        => true
      }.merge(@options)

      if options[:width] || options[:height]
        @data = process(options[:width], options[:height])
      end

      path = "#{Settings.path.guides_generated}/#{guide_id}/#{options[:type]}"

      FileUtils.mkdir_p(path) if !File.exists?(path)

      local_file = File.open("#{path}/#{@name}.#{options[:extension]}", 'wb+')
      local_file.write(data)
      local_file.close
  
      ["guides/#{guide_id}/#{options[:type]}/#{@name}.#{options[:extension]}", File.size("#{path}/#{@name}.#{options[:extension]}")]
    end

  end
end