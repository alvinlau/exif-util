require './exif_util'
require 'rspec/collection_matchers'

RSpec.describe 'ExifUtil' do  
  describe 'get image files' do
    image_types = %w(jpg jpeg png tiff).join ','
    
    it 'adds the proper glob syntax suffix without given directory' do
      expect(Dir).to receive(:glob).with('**/*' + ".{#{image_types}}")
      files = ExifUtil::get_image_files(nil)
      expect(files).to be_empty
    end
    
    
    it 'adds the proper glob syntax suffix given directory' do
      allow(File).to receive(:directory?).with('some_dir').and_return(true)
      expect(Dir).to receive(:glob).with('some_dir/**/*' + ".{#{image_types}}")
      files = ExifUtil::get_image_files('some_dir')
      expect(files).to be_empty
    end
    
    
    it 'accepts empty string directory' do
      expect(Dir).to receive(:glob).with('**/*' + ".{#{image_types}}")
      files = ExifUtil::get_image_files('')
      expect(files).to be_empty
    end
    
    
    it 'does not include directories as files' do
      # first false is for the initial condition File.directory?(dir)
      # the rest are mocking the results from the glob as [dir, file, file]
      allow(File).to receive(:directory?).and_return(false, true, false, false)
      file = {}
      expect(Dir).to receive(:glob).with('**/*' + ".{#{image_types}}").and_return([file, file, file])
      files = ExifUtil::get_image_files(nil)
      expect(files).to have(2).files
    end
  end
  
  
  describe 'import exif data' do
    long = '[(10/1), (41/1), (55324/1253)]'
    lat = '[(59/1), (55/1), (37417/1285)]'
      
    it 'does not drop adding rows corresponding to files on parse error' do
      files = ['', '', '', '', '']
      allow(ExifUtil).to receive(:get_image_files).and_return(files)
      allow(File).to receive(:open).and_return(Object.new)
      
      data = double('Exif::Data')
      allow(data).to receive(:gps_longitude).and_return(long)
      allow(data).to receive(:gps_latitude).and_return(lat)
      allow(Exif::Data).to receive(:new) do
        raise Exif::NotReadable if [true,false].sample
        data
      end
      rows = ExifUtil::import('')
      expect(rows).to have(files.size).rows
    end
    
    
    it 'imports gps data for valid files' do
      files = ['some_file']
      allow(ExifUtil).to receive(:get_image_files).and_return(files)
      allow(File).to receive(:open).and_return(Object.new)
    
      data = double('Exif::Data')
      allow(data).to receive(:gps_longitude).and_return(long)
      allow(data).to receive(:gps_latitude).and_return(lat)
      allow(Exif::Data).to receive(:new).and_return(data)
      
      rows = ExifUtil::import('')
      expect(rows.first).to have(3).columns
      expect(rows.first).to eq(['some_file',long,lat])
    end
    
    
    it 'still adds filename for files without exif data' do
      files = ['some_file']
      allow(ExifUtil).to receive(:get_image_files).and_return(files)
      allow(File).to receive(:open).and_return(Object.new)
    
      data = double('Exif::Data')
      allow(Exif::Data).to receive(:new).and_raise(Exif::NotReadable)
      
      rows = ExifUtil::import('')
      expect(rows.first).to have(1).column
      expect(rows.first).to eq(['some_file'])
    end
  end
  
  
  describe 'export' do
    it 'does not export to file if there are no rows' do
      expect(CSV).not_to receive(:open)
      ExifUtil::export([], 'csv')
    end
  end
  
  
  describe 'csv export' do
    it 'write the right amount of rows to csv file' do
      rows = [[],[],[],[]]
      csv = double('CSV')
      allow(CSV).to receive(:open).and_return(csv)
      allow(csv).to receive(:<<).and_return(nil).exactly(rows.size).times
      # checking the data is written directly will require us to open a file everytime the test is run
      # here the best we can do is checking the right data is sent
      # however I couldn't get around to check the fields with a .with() for the :<< call
      # I would spend more time to get that right
      ExifUtil::export(rows, 'csv')
    end
  end
  
  
  describe 'html export' do
    it 'sends the right scope object to be rendered' do
      rows = [[],[],[],[]]
      temp = double('Slim::Template')
      expect(Slim::Template).to receive(:new).and_return(temp)
      # expect(temp).to receive(:render).with(instance_of ExifUtil::SlimScope)
      # as further work, I want to verify that the scope object has the right dir and rows set
      expect(temp).to receive(:render).with(duck_type(:dir, :rows))
      ExifUtil::export(rows, 'html', dir: 'some_dir')
    end
    # need to parse the slim rendered html file
    # there are gems such as nokogiri, but out of scope for this exercise
  end
end