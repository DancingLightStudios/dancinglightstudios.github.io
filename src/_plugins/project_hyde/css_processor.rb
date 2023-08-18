module Jekyll
  class Renderer
    def render_layout(output, layout, info)
      ProjectHyde::CssProcessor.new(layout, info).process

      # Would be nice to call super here instead of cloned logic
      payload["content"] = output
      payload["layout"] = Utils.deep_merge_hashes(layout.data, payload["layout"] || {})

      render_liquid(
        layout.content,
        payload,
        info,
        layout.path
      )
    end
  end
end

module ProjectHyde
  # Concatenates, minify, and hash a page's css
  # ---
  # css:
  #   - one.css
  #   - two.css
  # ---
  # will combine one.css and two.css (in order), hash the resulting file contents
  # and replace the property before rendering stage
  # page.css_files will be relative url to the hashed file
  #
  # Combined with layouts, a layouts css files will be handled the same as above
  # but will exist as a separate file and placed into the array page.css_files.
  # This handles sub layouts as well, resulting in an array of layouts and page css files
  #
  # Ordering is based on highest level layout to page.
  # default.css > blog.css > post.css
  class CssProcessor
    def initialize(layout, info)
      @registers = info[:registers]
      @site = @registers[:site]
      @page = @registers[:page]
      @data = layout.data
      @config = @site.config
      @asset_path = @config["css"]["path"]
      @source_path = File.join(*[@site.source, @asset_path].compact)

      if @page["css"].nil?
        @page["css"] = []
      else
        @page["css"] = [@page["css"]]
      end
    end

    def process
      @page["css"].unshift(@data["css"])

      file_groups = flatten_group(@page["css"])

      css_files = []

      for files in file_groups
        data = concatenate_files(files)

        next if data == ""

        data = minify(data)
        file = generate_file(data)
        css_files << file.url

        # file already exists, so skip writing out the data to disk
        next if @site.static_files.find { |x| x.name == file.name }

        # place file data into the new file
        file.file_contents = data

        # assign static file to list for jekyll to render
        @site.static_files << file
      end

      # the recursive nature of this will sometimes have duplicate css files
      @page["css_files"] = css_files.uniq
    end

    private

    def flatten_group(arr, acc = [])
      return [arr] if !arr.last.is_a?(Array)

      acc += [arr.first]
      acc += flatten_group(arr.last)
    end

    def concatenate_files(files, data = "")
      return data if !files&.length

      for file in files
      # tmp page required to handle anything with frontmatter/yaml header
        tmp_page = Jekyll::PageWithoutAFile.new(@site, nil, @asset_path, file)

        file_contents = File.read(@source_path + file)
        tmp_page.content = file_contents
        data << Jekyll::Renderer.new(@site, tmp_page).run
      end

      data
    end

    def minify(data)
      return data if !@config["css"]["style"] == "compressed"

      converter_config = {"sass" => {"style" => "compressed"}}
      Jekyll::Converters::Scss.new(converter_config).convert(data)
    end

    def generate_file(data)
      hashed_file_name = Digest::MD5.hexdigest(data) + ".css"
      ProjectHyde::GeneratedStaticFile.new(@site, @asset_path, hashed_file_name)
    end
  end

  # Alternative class for jekyll's static files
  # this allows the creation of files without a source file
  class GeneratedStaticFile < Jekyll::StaticFile
    attr_accessor :file_contents

    def initialize(site, dir, name)
      @site = site
      @dir = dir
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

      File.open(dest_path, "w") do |output_file|
        output_file << file_contents
      end

      true
    end
  end
end
