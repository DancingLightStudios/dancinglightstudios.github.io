require "terser"

# Compress js files with frontmatter headers
Jekyll::Hooks.register :pages, :post_render do |page|
  # only operate on css files
  if page.ext == '.js' then
    config = page.site.config
    @asset_style = config['page_js']['minify'] || false

    # js minification
    converter_config = { :mangle => false, :output => { :comments => :copyright } }
    js_converter = Terser.new(converter_config)
    page.output = js_converter.compile(js_output)
  end
end

