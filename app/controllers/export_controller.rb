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
      @json[:language] = 'fr' if @guide_id.include?('.01')
      @json[:language] = 'de' if @guide_id.include?('.02')
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
      url: "http://#{request.host_with_port}/static_files/fr_logo.png",
      size: @logo_file.size,
    }

    @json[:styles][:background_image] = {
      path: 'background.jpg',
      url: "http://#{request.host_with_port}/static_files/fr_background.jpg",
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
      start_date: ((Date.today + 1.year).beginning_of_year).strftime('%Y-%m-%d'),
      end_date: ((Date.today + 1.year).beginning_of_year + 6.days).strftime('%Y-%m-%d'),
      language: "en",
      country: "United States",
      styles: {
        "home-background-transparent" => "false",
        "background_colour" => "#ffffff",
        "home-shadow-enabled" => "true",
        "home-separator-transparent" => "false",
        "home-shadow" => "5",
        "home-border-radius" => "0",
        "home-header-logo-container-enabled" => "true",
        "home-header-title-container-enabled" => "true",
        "home-separator-height" => "5",
        "home-separator-color" => "#D00926",
        "home-header-title-color" => "#000000",
        "home_buttons" => "#00519E",
        "hover_home_button_colour" => "#D4102C",
        "home-button-title-color" => "#FFFFFF",
        "home-button-title-color-hover" => "#FFFFFF",
        "toolbar_buttons" => "#FFFFFF",
        "home-button-icon-color" => "#FFFFFF",
        "home-button-icon-color-hover" => "#FFFFFF",
        "home-button-space-transparent" => "false",
        "home-button-space-color" => "#ffffff",
        "home-button-border-color" => "#ffffff",
        "toolbar" => "#00519e",
        "navbar_buttons" => "#FFFFFF",
        "hover_nav_button_colour" => "#D4102C",
        "nav_tile_colour" => "#FFFFFF",
        "button_title" => "#000000",
        "button_subtitle" => "#7A7A7A",
        "button_subtitle_2" => "#7A7A7A",
        "list_separator" => "#ccd7dd",
        "day_background" => "#E2E4EA",
        "poi_text" => "#D4102C",
        "caption_text" => "#000000",
        "caption_background" => "#ffffff",
        "bold_text" => "#000000",
        "guides-tablet-items-title-font-color" => "#ffffff",
        "guides-tablet-items-subtitle-font-color" => "#ffffff",
        "email_links" => "#00519E",
        "appearance_travellers_site_topics" => "#000000",
        "appearance_travellers_site_links" => "#0067A9",
        "appearance_travellers_site_background" => "#FFFFFF",
        "appearance_travellers_site_hover" => "#3E6B8A"
      },
      maps: [],
      schedule: [],
      contacts: [
        {
          address1: "",
          address2: "",
          city: "",
          company: "Emirates",
          email: "",
          emergency_phone: "+44 844 800 2777",
          phone: "",
          fax: "",
          zip: "",
          comment: "",
          website: "",
          category: "Airline",
          country: "United Kingdom",
          images: []
        },
        {
          address1: "",
          address2: "",
          city: "",
          company: "Kuredu Island Resort",
          email: "",
          emergency_phone: "",
          phone: "0096 596 236 52",
          fax: "",
          zip: "",
          comment: "",
          website: "",
          category: "Hotel",
          country: "Maldives",
          images: []
        }
      ],
      documents: [],
      guides: []
    }
  end

end
