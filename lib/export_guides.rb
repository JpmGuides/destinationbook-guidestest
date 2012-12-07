# encoding: utf-8
require 'export_guides/guide'
require 'export_guides/image'

class ExportGuides
  IMAGE_FILE = ['jpg', 'jpeg', 'png', '.jpg', '.jpeg', '.png']

  def self.get_guide_json(guide_id)
    guide_head = ("#{Settings.path.guides_generated}/#{guide_id}/guide.json")

    {id: guide_id, generated_at: guide_head.last_modified, url: guide_head.url(1.hour.since.to_i), file_count: guide_head.metadata['x-amz-meta-nb-file']}
  end

  def guides_to_update
    guides_to_update= []

    Dir.glob("#{Settings.path.guides_zip}/*.zip").each do |file|
      
      guide_id = File.basename(file, '.*')
      guide_last_modif = File.mtime(file).to_i

      if  @force_update || (guide_last_modif > Rails.cache.read("last_modified_#{guide_id}").to_i) || File.exists?("#{Settings.path.guides_generated}/#{guide_id}/guide.json") && (Rails.cache.read("on_error_#{guide_id}").nil? || Rails.cache.read("on_error_#{guide_id}") < guide_last_modif) 
        guides_to_update << Guide.new(guide_id, file) 
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
          guide.zip_data = Zip::ZipFile.open(guide.path)

          guide.generate
        rescue => e 
          puts "error on guide #{guide.id} : #{e.message}"
          Rails.logger.error("error on guide #{guide.id} : #{e.message}")
          Rails.cache.write("on_error_#{guide.id}",  File.mtime(guide.path).to_i)
        end
      end
      Rails.cache.write('updating_guides', false)
    end

    true
  ensure
    Rails.cache.write('updating_guides', false)
  end

end