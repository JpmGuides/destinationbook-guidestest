# encoding: utf-8
require 'export_guides/guide'
require 'export_guides/image'

class ExportGuides
  IMAGE_FILE = ['jpg', 'jpeg', 'png', '.jpg', '.jpeg', '.png']

  def self.get_guide_json(guide_id)
    guide_head = aws_bucket_directory.files.head("#{ENV['GUIDE_PATH']}/#{guide_id}/guide.json")

    {id: guide_id, generated_at: guide_head.last_modified, url: guide_head.url(1.hour.since.to_i), file_count: guide_head.metadata['x-amz-meta-nb-file']}
  end

  def self.get_background_image(image_name)
    aws_bucket_directory.files.head("export_cache/backgrounds/#{image_name}.jpg").url(1.hour.since.to_i)

  # return nil if file don't exist
  rescue
    nil
  end

  def self.get_logo(path)
    aws_bucket_directory.files.head(path).url(1.hour.since.to_i)

  # return nil if file don't exist
  rescue
    nil
  end

  def self.aws_bucket_connection
    Fog::Storage.new({
      :provider                 => 'AWS',
      :aws_access_key_id        => ENV['AWS_ACCESS_KEY_ID'],
      :aws_secret_access_key    => ENV['AWS_SECRET_ACCESS_KEY'],
      :region                   => ENV['AWS_REGION']
    })
  end

  def self.aws_bucket_directory
    aws_bucket_connection.directories.get(ENV["S3_BUCKET"])
  end

  def directory
    @directory ||= self.class.aws_bucket_directory
  end

  def update_backgrounds

    directory.files.all(:prefix => 'backgrounds').each do |file|
      type = File.extname(file.key)
      
      if IMAGE_FILE.include?(type)
        backgound_name = File.basename(file.key, '.*')

        if (directory.files.head("export_cache/backgrounds/#{File.basename(file.key)}").nil? || (file.last_modified.to_datetime.to_i > Rails.cache.read("last_modified_background_#{backgound_name}").to_i)) && !file.key.include?('_gen_')
          image = ExportGuides::Image.new(backgound_name, file.body, '0', {extension: type, height: 1136, width: nil, key: "export_cache/backgrounds/#{File.basename(file.key)}", pub: false})
          image.save
          Rails.cache.write("last_modified_background_#{backgound_name}",  file.last_modified.to_datetime.to_i)
        end
      end
    end

    true
  end

  def guides_to_update
    guides_to_update= []

    directory.files.all(:prefix => ENV['GUIDE_PATH']).each do |file|
      type = File.extname(file.key)
      
      if type == '.zip'
        guide_id = File.basename(file.key, '.*')

        if  @force_update || 
          ((file.last_modified.to_datetime.to_i > Rails.cache.read("last_modified_#{guide_id}").to_i) || directory.files.head("#{ENV['GUIDE_PATH']}/#{guide_id}/guide.json").nil?) && (Rails.cache.read("on_error_#{guide_id}").nil? || Rails.cache.read("on_error_#{guide_id}") < file.last_modified.to_datetime.to_i) 
          guides_to_update << Guide.new(guide_id, file.key) 
        end
      end
    end

    guides_to_update
  end

  def update_guides(force = false)
    if !Rails.cache.read('updating_guides')
      @force_update = force
      Rails.cache.write('updating_guides', true)

      guides_to_update.each do |guide|
        begin
          local_guide_file = "#{Rails.root}/tmp/#{guide.id}_#{Process.pid}.zip"
              
          local_guide = File.open(local_guide_file, 'wb') 
          local_guide.write(directory.files.get(guide.s3_path).body)
          local_guide.close

          guide.zip_data = Zip::ZipFile.open(local_guide_file)

          guide.generate
        rescue => e 
          Rails.logger.error("error on guide #{guide.id} : #{e.message}")
          Rails.cache.write("on_error_#{guide.id}",  ExportGuides.aws_bucket_directory.files.head(guide.s3_path).last_modified.to_datetime.to_i)
        end
      end
      Rails.cache.write('updating_guides', false)
    end

    update_backgrounds

    true

  ensure
    Rails.cache.write('updating_guides', false)
  end

end