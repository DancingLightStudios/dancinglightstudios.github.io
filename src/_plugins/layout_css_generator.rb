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

  class LayoutCssGenerator < Generator
    def generate(site)
      config = site.config
      @asset_path = config['page_css']['path']
      @asset_style = config['page_css']['style'] || false

      return unless @asset_path

      @source_path = File.join(*[site.source, @asset_path].compact)

      layouts = site.layouts

      for name, layout in layouts do
        files = layout.data['css']
        next if files.nil?

        css_output = ''

        for file in files do
          file_contents = File.read(@source_path + file)
          tmp_page = Jekyll::PageWithoutAFile.new(site, nil, @asset_path, name + '.css')
          tmp_page.content = file_contents
          css_output << Jekyll::Renderer.new(site, tmp_page).run()
        end

        # css minification
        if @asset_style
          converter_config = { 'sass' => { 'style' => @asset_style } }
          css_converter = Jekyll::Converters::Scss.new(converter_config)
          css_output = css_converter.convert(css_output)
        end

        hashed_file_name = Digest::MD5.hexdigest(css_output) + '.css'

        file = Jekyll::GeneratedStaticFile.new(site, @asset_path, hashed_file_name)
        layout.data['css'] = file.url

        # skip file for output if already in the list
        return if site.static_files.find { |x| x.name == file.name }

        file.file_contents = css_output

        # append file to site for processing
        site.static_files << file
      end
    end
  end
end
