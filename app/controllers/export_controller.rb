class ExportController < ApplicationController

  def show
    @guide_id = params[:authentication_token]
    zip_path = "#{Settings.path.guides_generated}/#{@guide_id}/guide.zip"
    @logo_file = File.open("#{Rails.root}/public/static_files/logo.png")
    @background_file = File.open("#{Rails.root}/public/static_files/background.jpg")

    @number_files = 0
    @files_size = 0
    @export_guides = true

    if File.exists?(zip_path)
      @json = base_json.deep_dup
      add_files_to_json

      render json: @json, type: 'application/json', disposition: 'inline'
    else
      render nothing: true, status: 404
    end
  end

  private

  def add_files_to_json
    guide_json = ExportWallet::Guide.get(@guide_id)
    guide_json.merge!({
      id: @guide_id,
      url: "http://#{request.host_with_port}/guides/#{@guide_id}/guide.zip",
      order: 1,
    })

    @json[:guides] = [guide_json]

    @json[:styles][:logo] = {
      path: 'logo.png',
      url: "http://#{request.host_with_port}/static_files/logo.png",
      size: @logo_file.size,
    }

    @json[:styles][:background_image] = {
      path: 'background.jpg',
      url: "http://#{request.host_with_port}/static_files/background.jpg",
      size: @background_file.size,
    }

    @json[:file_count] = 3
    @json[:files_size] = guide_json[:size].to_i + @logo_file.size + @background_file.size
  end

  def base_json
    {
      version: "1.0.0",
      token: "TEST",
      name: "Your Trip",
      description: "",
      reference: "123456",
      start_date: "2015-01-01",
      end_date: "2015-01-10",
      language: "en",
      country: "United States",
      styles: {
        background_colour: "#ffffff",
        trip_title_colour: "#000000",
        home_buttons: "#877E77",
        hover_home_button_colour: "#BD2430",
        toolbar_buttons: "#FFFFFF",
        rounded_corners: "0",
        toolbar: "#877e77 0%, #7b736d 40%, #68615c 100%",
        navbar_buttons: "#FFFFFF",
        hover_nav_button_colour: "#BD2430",
        nav_tile_colour: "#FFFFFF",
        button_title: "#000000",
        button_subtitle: "#7A7A7A",
        button_subtitle_2: "#7A7A7A",
        list_separator: "#d3d1cb 0%, #bab8b2 100%",
        day_background: "#FCF6D6",
        poi_text: "#BD2430",
        caption_text: "#000000",
        caption_background: "#FFFFFF",
        bold_text: "#000000",
        email_links: "#7A7A7A",
      },
      maps: [],
      schedule: [],
      contacts: [],
      documents: [],
      guides: []
    }
  end

end
