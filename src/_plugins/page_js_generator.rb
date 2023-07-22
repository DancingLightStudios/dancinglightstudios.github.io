require "terser"
require "digest"

module Jekyll
  # Override class for jekyll's static files
  # this allows the creation of files without a source file
  class GeneratedStaticFile < Jekyll::StaticFile
    attr_accessor :file_contents

    def initialize(site, dir, name)
      @site = site
      @dir  = dir
      @name = name
      @relative_path = File.join(*[@dir, @name].compact)
      @extname = File.extname(@name)
      @type = @collection&.label&.to_sym
    end

    def write(dest)
      dest_path = destination(dest)
      return false if File.exist?(dest_path)

      FileUtils.mkdir_p(File.dirname(dest_path))
      FileUtils.rm(dest_path) if File.exist?(dest_path)

      File.open(dest_path, 'w') do |output_file|
        output_file << file_contents
      end

      true
    end
  end

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

        file = Jekyll::GeneratedStaticFile.new(site, @asset_path, hashed_file_name)
        file.file_contents = js_output
        page.data['js'] = file.url

        # append file to site for processing
        site.static_files << file
      end
    end
  end
end
