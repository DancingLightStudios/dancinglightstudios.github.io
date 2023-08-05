require "digest"

module Jekyll
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

      docs = []

      # Pages with the frontmatter css
      docs += site.pages.select { |page| page.data.include? 'css' }

      # collections with the frontmatter css
      # NOTE documents/collections/pages need to come before layouts
      #      not sure why, but after the layouts are processed
      #      static files can't be writen to anymore.
      #      `site.static_files << file`
      #      fails silently.
      for _type, collection in site.collections do
        docs += collection.docs.collect { |doc| doc if doc.data.include? 'css' }.compact
      end

      # layouts
      docs += site.layouts.collect { |_, layout| layout if layout.data.include? 'css' }.compact

      for doc in docs do
        files = doc.data['css']
        next if files.nil?

        css_output = ''

        for file in files do
          # layouts and pages/docs havae different filenaame and extension methods
          if doc.respond_to?(:name)
            name = File.basename(doc.name, doc.ext)
          elsif doc.respond_to?(:basename)
            name = File.basename(doc.basename, doc.extname)
          end

          tmp_page = Jekyll::PageWithoutAFile.new(site, nil, @asset_path, name + '.css')
          file_contents = File.read(@source_path + file)
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
        doc.data['css'] = file.url

        # skip file for output if already in the list
        next if site.static_files.find { |x| x.name == file.name }

        file.file_contents = css_output

        # append file to site for processing
        site.static_files << file
      end
    end
  end
end

