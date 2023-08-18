require 'uri'
require 'net/http'

module Jekyll
  class FontsGenerator < Generator
    def generate(site)
      @config = site.config
      return unless @config['fonts']['path']
      return if !site.data['fonts']

      @asset_path = @config['fonts']['path']
      @faces = site.data['fonts']['fonts']['faces']
      @variable = @config['fonts']['variable']

      #
      # 1. Generate Google Fonts link uri
      #
      uri = faces_uri

      #
      # 2. Download contents of uri
      #
      headers = {
        "User-Agent": 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/117.0'
      }

      # puts uri

      uri_payload = Net::HTTP.get(uri, headers)

      #
      # 3. Parse contents to fonts
      #
      rulesets = CssFontsData.new(uri_payload).rulesets

      #
      # 4. Fetch Fonts
      # 5. Create static font files
      #
      for ruleset in rulesets
        filename = ruleset.filename.gsub(/[\s]/, '_')
        file = ProjectHyde::GeneratedStaticFile.new(site, @asset_path, filename)

        destination_fname = file.destination('./')
        next if File.exist?(destination_fname)
        puts "Downloading Font: #{filename}"

        font_uri_payload = Net::HTTP.get(ruleset.uri)
        file.file_contents = font_uri_payload

        site.static_files << file
      end

      #
      # 6. Generate css file with local assets
      #
      css = []
      for ruleset in rulesets
        css.push(ruleset.local_ruleset(@asset_path))
      end

      css_file = ProjectHyde::GeneratedStaticFile.new(site, @asset_path, 'fonts.css')
      css_file.file_contents = css.join("\n") #minify(css.join("\n"))
      site.static_files << css_file
    end

    private

    def faces_uri
      google_uri_base = 'https://fonts.googleapis.com/css2'
      params = [['display', 'swap']]

      for face in @faces
        params.push(['family', FontFace.new(face, @variable).to_s])
      end

      uri = google_uri_base + '?' + params.map { |param| param.join('=') }.join('&')

      URI(uri)
    end

    def minify(data)
      return data if !@config['css']['style'] == 'compressed'

      converter_config = { 'sass' => { 'style' => 'compressed' } }
      Jekyll::Converters::Scss.new(converter_config).convert(data)
    end
  end

  class CssFontsData
    attr_reader :rulesets

    def initialize(css)
      @rulesets = css.scan(/\/\*[^}]*}/)

      @rulesets = @rulesets.map do |raw_ruleset|
        CssFontRuleset.new(raw_ruleset)
      end
    end
  end

  class CssFontRuleset
    attr_reader :filename, :char_set, :family, :style, :weight, :uri, :format, :ruleset, :local_rule_set

    def initialize(raw_css_ruleset)
      @ruleset = raw_css_ruleset

      /\/\* (?'character_set'.*) \*\// =~ raw_css_ruleset
      /^\s*font-family:\s'(?'family'[\w\s]*)';$/ =~ raw_css_ruleset
      /^\s*font-style:\s(?'style'[\w]*);$/ =~ raw_css_ruleset
      /^\s*font-weight:\s(?'weight'[\w\s]*);$/ =~ raw_css_ruleset
      /\s\ssrc:\surl\((?'uri'.*)\)\s.*\('(?'format'.*)'\);$$/ =~ raw_css_ruleset

      @char_set = character_set
      @family = family
      @style = style
      @weight = weight
      @uri = URI(uri)
      @format = format

      @filename = [@family.gsub(/[\s]/, '_'), @style, @weight.gsub(/[\s]/, '_'), @char_set + '.' + @format].join('_')
    end

    def local_ruleset(path)
      @ruleset.gsub(/(?<=url\().*(?=\)\s)/, '/' + File.join(path, @filename))
    end
  end

  class FontFace
    def initialize(face, variable = false)
      @family = face['name']
      @variants = []
      @variable = variable

      for variant in face['weights']
        @variants.push(FontVariant.new(weight: variant['value'], italic: variant['italic']))
      end
    end

    def sort_variants(variants)
      variants.sort do |a, b|
        (a.italic == b.italic) ? a.weight <=> b.weight : a.italic <=> b.italic
      end
    end

    def to_s
      if @variable
        normal = []
        italic = []

        @variants.each do |variant|
          if variant.italic == 1
            italic.push(variant)
          else
            normal.push(variant)
          end
        end

        normal.sort { |a,b| a.weight <=> b.weight }
        italic.sort { |a,b| a.weight <=> b.weight }

        normal = "0,#{normal.first.weight.to_s}..#{normal.last.weight.to_s}"
        italic = "1,#{italic.first.weight.to_s}..#{italic.last.weight.to_s}"

        @family + ':ital,wght@' + [normal, italic].join(';')
      else
        variants = sort_variants(@variants).map { |variant| variant.to_s }

        @family + ':ital,wght@' + variants.join(';')
      end
    end
  end

  class FontVariant
    attr_reader :italic, :weight

    def initialize(weight:, italic:)
      @weight = weight
      @italic = 0

      if italic == true
        @italic = 1
      end
    end

    def to_s
      @italic.to_s + ',' + @weight.to_s
    end
  end
end
