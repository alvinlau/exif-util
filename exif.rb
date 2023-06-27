require 'optparse'
require './exif_util'

# parse command options
# https://ruby-doc.org/stdlib-2.4.2/libdoc/optparse/rdoc/OptionParser.html
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"
  opts.on("-dDIR", "--dir=DIR", "directory to search for images") do |d|
    options[:dir] = d
  end

  opts.on("-fFMT", "--formatFMT", "output format (csv or html)") do |f|
    options[:fmt] = f if ['csv', 'html'].include? f
  end
end.parse!
p 'options', options
  
output = ExifUtil::import(options[:dir])
ExifUtil::export(output, options[:fmt], dir: options[:dir])
