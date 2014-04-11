class StatusWriter

  def initialize(root)
    @root = root

    check_directory
  end

  def check_directory
    if !File.exists?("#{@root}/public/status")
      FileUtils.mkdir_p("#{@root}/public/status/")
    end
  end

  def file_path(mime_type)
    path = "#{@root}/public/status/status.#{mime_type}"

    if !File.exists?(path)
      FileUtils.touch(path)
    end

    path
  end

  def get_current_status
    File.open(file_path('json'), 'r') do |file|
      status = JSON.parse(file.read) rescue []
    end
  end

  def write_html
    path = file_path('html')
    status = get_current_status

    doc = Nokogiri::HTML(html_base)
    main = doc.at_css('#main')

    status_node = []
    status.each do |stat|
      div = Nokogiri::XML::Node.new("div", doc)
      div['class'] = "status-container #{stat['status']}"

      span_date = Nokogiri::XML::Node.new("span", doc)
      span_date['class'] = 'date'
      span_date.content = Time.at(stat['time']).to_datetime.strftime('%H:%M - %d/%m/%Y')

      span_guide_id = Nokogiri::XML::Node.new("span", doc)
      span_guide_id['class'] = 'guide'
      span_guide_id.content = stat['guide_id']

      span_status = Nokogiri::XML::Node.new("span", doc)
      span_status['class'] = 'status'
      span_status.content = stat['status']

      span_message = Nokogiri::XML::Node.new("span", doc)
      span_message['class'] = 'message'
      span_message.content = stat['message']

      main.add_child(div)
      div.add_child(span_date)
      div.add_child(span_guide_id)
      div.add_child(span_status)
      div.add_child(span_message)
    end

    File.open(path,'w') do |file|
      file.write(doc)
    end

    self
  end

  def write_json(status)
    path = file_path('json')
    status = get_current_status.unshift(status)

    if status.count >= 50
      status = status.shift(50)
    end

    File.open(path, 'w') do |file|
      file.write(status.to_json)
    end

    self
  end

  private

  def html_base
    self.class.html_base
  end

  def self.html_base
    <<-HTML
      <html>
        <head>
          <title>Guides Generation Status</title>
          <meta http-equiv="refresh" content="10">
          <style type="text/css">
            #main {
              width: 1200px;
              margin: auto;
            }

            #title {
              width: 1200px;
              margin: auto;
            }

            .status-container {
              width: 100%;
              height: 25px;
            }

            span {
              display: block;
              float: left;
              height: 25px;
              line-height: 25px;
            }

            .error {
              background-color: rgb(204, 0, 0);
              background-color: rgba(204, 0, 0, 0.4);
            }

            .successfull{
              background-color: rgb(102, 204, 0);
              background-color: rgba(102, 204, 0, 0.4);
            }

            .date {
              width: 150px;
            }

            .guide {
              width: 150px;
            }

            .status {
              width: 150px;
            }

            .message {
              width: 750px;
            }
          </style>
        </head>
        <body>
          <div id="title">
            <h1>Guide Generation Status</h1>
          </div>
          <div id="main">
          </div>
        </body>
      </html>
    HTML
  end
end
