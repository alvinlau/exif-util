require 'exif'
require 'csv'
require 'pp'
require 'slim'

module ExifUtil
  def ExifUtil.import(dir)
    # read the image files and extract gps data
    output = []
    
    get_image_files(dir).each do |filename|
      begin
        data = Exif::Data.new(File.open(filename))
      rescue Exif::NotReadable
        # no valid exif data for this file
        output << [File.basename(filename)]
      else # only when no exceptions
        # what if the coordinates are nil?
        output << ( data.gps_longitude && data.gps_latitude ?
          [File.basename(filename), data.gps_longitude, data.gps_latitude] :
          [File.basename(filename)] )
      ensure
        # nice to have finally block
      end
    end
    
    # just print first couple rows and the last one for visibility and debugging
    pp output.take(5)
    p '...'
    pp output.last
    
    output
  end

  
  def ExifUtil.get_image_files(dir)
    # accepted image file types could be a global
    image_types = %w(jpg jpeg png tiff).join ','
    
    # set the directory  
    dir = if dir && File.directory?(dir)
      p "searching in #{dir}"
      dir + '/'
    end || ''
    
    glob = Dir.glob(dir + '**/*' + ".{#{image_types}}")
    glob.nil? ? [] : glob.reject{|filename| File.directory?(filename)}
  end
    
    
  class SlimScope
    attr_accessor :dir, :rows
  end
  
  
  def ExifUtil.export(rows, fmt, dir: nil)
    # write out the results to file
    unless rows.empty?
      if fmt == 'html'        
        scope = SlimScope.new
        scope.dir = File.expand_path(dir) if dir
        scope.rows = rows
        
        html = Slim::Template.new('output.slim').render(scope)
        File.open(Time.now.utc.strftime("%Y%m%d%H%M%S") + '.html', "w") do |file|
          file.write html
        end
      else
        CSV.open(Time.now.utc.strftime("%Y%m%d%H%M%S") + '.csv', "w") do |csv|
          rows.each{|row| csv << row}
        end
      end
    end
  end  
end


# References
# https://github.com/tonytonyjan/exif
# https://stackoverflow.com/questions/2370702/one-liner-to-recursively-list-directories-in-ruby
# https://stackoverflow.com/questions/2943065/how-to-get-utc-timestamp-in-ruby
# https://stackoverflow.com/questions/4822422/output-array-to-csv-in-ruby
# https://www.thoughtco.com/using-glob-with-directories-2907832
# https://github.com/slim-template/slim
# https://stackoverflow.com/questions/27020433/how-to-use-slim-directly-in-ruby