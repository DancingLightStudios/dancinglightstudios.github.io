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

  # Concatenates, hashes a page's css
  # ---
  # css:
  #   - one.css
  #   - two.css
  # ---
  # will combine one.css and two.css (in order), hash the resulting file contents
  # and replace the property before rendering stage
  # {{ page.css }} will be relative url to the hashed file
  class PageCssGenerator < Generator
    def generate(site)
      config = site.config
      @asset_path = config['page_css']['path']
      @asset_style = config['page_css']['style'] || false

      return unless @asset_path

      @source_path = File.join(*[site.source, @asset_path].compact)

      # Pages with the frontmatter css
      pages = site.pages.select { |page| page.data.include? 'css' }

      # collections with the frontmatter css
      for type, collection in site.collections do
        for doc in collection.docs do
          pages << doc if doc.data.include? 'css'
        end
      end

      for page in pages do
        files = page.data['css']
        next if files.nil?

        css_output = ''

        for file in files do
          css_output << File.read(@source_path + file)
        end

        # css minification
        if @asset_style
          converter_config = { 'sass' => { 'style' => @asset_style } }
          css_converter = Jekyll::Converters::Scss.new(converter_config)
          css_output = css_converter.convert(css_output)
        end

        hashed_file_name = Digest::MD5.hexdigest(css_output) + '.css'

        file = Jekyll::GeneratedStaticFile.new(site, @asset_path, hashed_file_name)
        page.data['css'] = file.url

        # skip file for output if already in the list
        return if site.static_files.find { |x| x.name == file.name }

        file.file_contents = css_output

        # append file to site for processing
        site.static_files << file
      end
    end
  end
end

# Compress css files with frontmatter headers
Jekyll::Hooks.register :pages, :post_render do |page|
  # only operate on css files
  if page.ext == '.css' then
    config = page.site.config
    @asset_style = config['page_css']['style'] || false

    # css minification
    converter_config = { 'sass' => { 'style' => @asset_style } }
    css_converter = Jekyll::Converters::Scss.new(converter_config)
    page.output = css_converter.convert(page.output)
  end
end

