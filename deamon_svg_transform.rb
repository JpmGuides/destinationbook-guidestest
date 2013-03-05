require 'daemons'

options = {
  :dir_mode   => :script,
  :log_output => true,
  :ontop      => true,
  :multiple   => false
}

Daemons.run_proc('deamon_svg_transform.rb', options) do

end
