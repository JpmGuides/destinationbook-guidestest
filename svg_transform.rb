#!/bin/env ruby

require 'daemons'
require 'fileutils'
require 'listen'

# config
ROOT = File.expand_path(File.dirname(__FILE__))
INKSCAPE_PATH = '/Applications/Inkscape.app/Contents/Resources/bin/inkscape'
INPUT_DIRS = [
  File.join(ROOT, 'input', 'rotate-left'),
  File.join(ROOT, 'input', 'rotate-right')
]

# start demons
Daemons.run_proc('deamon_svg_transform.rb', {
  dir_mode:   :script,
  log_output: true,
  ontop:      true,
  multiple:   false
}) do

  raise "Inkscape should not be found at: #{INKSCAPE_PATH}" if !File.executable?(INKSCAPE_PATH)

  INPUT_DIRS.each do |dir|
    FileUtils.mkdir_p(dir)
    puts "* listening #{dir}"
  end
  FileUtils.mkdir_p(File.join(ROOT, 'processing'))
  FileUtils.mkdir_p(File.join(ROOT, 'result'))

  Listen.to(*INPUT_DIRS, latency: 5, filter: /\.svg/) do |modified, added|
    changes = modified + added

    changes.each do |input_path|
      processing_path = input_path.gsub(/input\/[^\/]+/, 'processing')
      result_path = input_path.gsub(/input\/[^\/]+/, 'result')

      if match = input_path.match(/rotate-(left|right)/)
        case match[1]
        when 'right'
          inkscape_verb_rotate = 'ObjectRotate90'
        when 'left'
          inkscape_verb_rotate = 'ObjectRotate90CCW'
        end

        print "* rotate #{File.basename(processing_path)}"

        FileUtils.move(input_path, processing_path, force: true)
        `#{INKSCAPE_PATH} #{processing_path} --verb=EditSelectAll --verb=SelectionGroup --verb=#{inkscape_verb_rotate} --verb=FitCanvasToSelectionOrDrawing --verb=FileSave --verb=FileClose > /dev/null  2>/dev/null`
        FileUtils.move(processing_path, result_path, force: true)

        if $?.exitstatus == 0
          puts ' done.'
        else
          puts ' fail.'
        end
      end
    end

  end
end
