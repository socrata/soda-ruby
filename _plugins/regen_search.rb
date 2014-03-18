# Copyright (c) 2012 by James Cammarata <jimi@sngx.net>
# 
# Permission is hereby granted, free of charge, to any person obtaining 
# a copy of this software and associated documentation files (the "Software"), 
# to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the 
# Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'json'
require 'ferret'

include Ferret

module Jekyll
    # Add accessor for directory
    # this lets us get the full path to the page
    class Page
        attr_reader :dir
    end

    # The file class we'll be generating
    class SearchData < StaticFile
        def write(dest)
            begin
                super(dest)
            rescue
            end
            true
        end
    end

    class SearchGenerator < Generator
        # This does nothing for github unfortunately...
        safe true

        def generate(site)
            # our ferret index, completely disposable
            index = Index::Index.new(:path => Dir.mktmpdir)

            # our list of every word in the document, sans-dupes
            all_words = []

            # the scores of words we'll be sending back
            word_scores = {}

            # the ferret to jekyll page index. This saves by using the ferret
            # id for the word scores rather than saving the full page data for 
            # every entry there 
            page_index = {}

            # loop through all the pages jekyll knows about...
            # this can take a bit of time, especially for large sites.

            pages = site.pages
            pages.each do |page|
                # add the page info to the ferret index
                index << {  
                  :title => page.data['title'],
                  :url => page.url,
                  :content => page.content,
                }

                # lump the title into the content just to make sure
                # we don't miss any words.
                toscan = "#{page.data['title']} #{page.content}"

                # Loop over all the words (after splitting, subbing, and downcasing)
                # and stick them into an array, avoiding dupes
                #
                # FIXME: this gsub is far from perfect. It doesn't capture 
                #        single or double quotes at the begining/end of a word
                #        and misses other stuff too, but it works well enough
                toscan.downcase.gsub(/[^a-z -\']/, ' ').split(" ").each do |word|
                    if word == ""
                        next
                    end
                    if !all_words.rindex(word)
                        all_words << word
                        word_scores[word] = []
                    end
                end
            end

            # Now we have all the words, and all the text is indexed, so lets run through
            # every word to generate a list of scores and documents that word occured in...
            # We use _short_ strings for hash keys to save space

            print "Generating search data for #{all_words.length()} words\n"
            all_words.each do |word|
                index.search_each("*: #{word}") do | id, score |
                    word_scores[word] << {"s"=>"%0.3f"%score,"u"=>"%s"%id}
                    if !page_index.has_key?(id)
                        page_index["%s"%id] = {"u"=>index[id][:url],"t"=>index[id][:title]}
                    end
                end 
            end

            begin
              # And now we dump the word_scores and page_index to a file in JSON format.
              # This is the file our jquery script will grab. All the actual search happens
              # in the web browser, since jekyll is static.
              file = File.new(File.join(site.dest, "search.json"), "w")
              file.write({"words"=>word_scores,"index"=>page_index}.to_json)
              file.close

              # Finally, add the json file to the static files list
              site.static_files << Jekyll::SearchData.new(site, site.dest, "/", "search.json")
            rescue Exception => e
              puts "An error occurred when generating the search.json file, probably because the output directory doesn't exist yet.\nThis isn't the end of the world, you just won't be able to search"
            end
        end
    end
end
