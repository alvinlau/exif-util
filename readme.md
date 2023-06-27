## How to Install

### Required libraries

[exif](https://github.com/tonytonyjan/exif) is the gem I used to extract EXIF data from image files.  It does require you have `libexif` itself installed on your system.
To install `libexif`:

```
brew install libexif             # Homebrew
sudo apt-get install libexif-dev # APT
```


[slim](https://github.com/slim-template/slim) is what I used to render html.


As for the gems, I've included a Gemfile, which you can just install via `bundle install` or `gem install exif slim`.
This also assumes you have ruby installed on your system already.
I did not specify any version dependencies thus far.


### Example commands:

```
# in the root folder with exif.rb
ruby exif.rb
ruby exif.rb -d <directory>
ruby exif.rb -f csv
ruby exif.rb -f html
ruby exit.rb -d <directory> -f html
```

It defaults to `csv` format if no format is specified.


### Running the tests

Assuming you have `rspec` gem installed, simply run `rspec` within the root folder

```
rspec
```


## Design Discussions

There are a couple EXIF gems for ruby, e.g. exifr, mini_exiftool and exiftool, that even the exif gem mentions.
The exif gem seems to be the best all-around solution with a clean interface and best performance.  
The only tradeoff is having to explicitly install the `libexif` on your system via brew or apt.


In terms of overall processing flow, in the current implementation, we're doing it in 2 phases, where we first read the list of files, and then write out the parsed data for each file.
It is a little easier to test and debug this way, but I think it would be more ideal to "stream" this where we write-out the parsed data for each file as they arrive.
This way if there's an error in the first phase (getting the files), or if there's a large volume of files to process, we don't delay or deny writing out data as soon as we already have some files fetched.


We may re-architect it to work in a streaming fashion if we really do expect a large volume of files as an expected case, here I provide a 2 phase approach as a simple demonstration.
There is some merit to this 2 phase bulk approach: we can potentially show the user the summary of the amount of files before processing them.



## Testing strategy and caveats

There's clear defined input and output for the main process of this app, which is the list of files and the output list of row data, so it's relatively easy to mock out.


However, with csv output, in real life I would test that the writeout line for each row, i.e. `csv_file.write(row)` to be called correctly in various scenario to check data integrity.

The write line function of the csv library is a separate responsibility, if we're using something other than the system csv library, then we will test that it indeed writes the rows to a file and check the file.
With our app, we're not going to test that the library does its job beyond small runs in our usage.  Ideally we'll write a few small tests for ensure the write function does what it promises.


Similarly, with html output, while we won't be testing the library (slim in this case), we can still verify the scope object has the right members (dir, rows), and perhaps basic scenrio for parsing back the html file to verify a few rows.
That's still outside the scope for this app in terms of time.  We can still do it as separate work.

