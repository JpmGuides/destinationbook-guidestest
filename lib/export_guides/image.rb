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

      file = ExportGuides.aws_bucket_directory.files.create(
        :key              => options[:key] || "#{ENV['GUIDE_PATH']}/#{@guide_id}/#{options[:type]}/#{@name}.#{options[:extension]}",
        :body             => ActiveSupport::Gzip.compress(@data),
        :content_type     => "image/#{options[:type]}",
        :content_encoding => 'gzip',
        :public           => options[:pub]
      )

      file.public_url
    end

  end
end