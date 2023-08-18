require "terser"
require "digest"

module Jekyll
  # Concatenates, hashes a page's js
  # ---
  # js:
  #   - one.js
  #   - two.js
  # ---
  # will combine one.js and two.js (in order), hash the resulting file contents
  # and replace the property before rendering stage
  # {{ page.js }} will be relative url to the hashed file
  class PageJsGenerator < Generator
    def generate(site)
      config = site.config
      @asset_path = config['page_js']['path']
      @asset_minify = config['page_js']['minify'] || false

      return unless @asset_path

      @source_path = File.join(*[site.source, @asset_path].compact)

      # Pages with the frontmatter js
      pages = site.pages.select { |page| page.data.include? 'js' }

      for page in pages do
        files = page.data['js']

        js_output = ''

        for file in files do
          js_output << File.read(@source_path + file)
        end

        # js minification
        if @asset_minify
          converter_config = { :mangle => false, :output => { :comments => :copyright } }
          js_converter = Terser.new(converter_config)
          js_output = js_converter.compile(js_output)
        end

        hashed_file_name = Digest::MD5.hexdigest(js_output) + '.js'

        file = ProjectHyde::GeneratedStaticFile.new(site, @asset_path, hashed_file_name)

        # skip file for output if already in the list
        # return if site.static_files.find { |x| x.name == file.name }

        file.file_contents = js_output
        page.data['js'] = file.url

        # append file to site for processing
        site.static_files << file
      end
    end
  end
end
