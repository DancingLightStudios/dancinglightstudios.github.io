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

