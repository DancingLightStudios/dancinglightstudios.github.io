if (window.screen.width >= 668 && !CSS.supports('grid-template-rows', 'masonry')) {
  masonryLayout('.masonry-stack')

  onresize = () => masonryLayout('.masonry-stack');
}

function masonryLayout(selector) {
  const container = document.querySelector(selector)
  if (!container) return;

  const contentBlocks = document.querySelectorAll(selector + ' p')
  const imageBlocks = document.querySelectorAll(selector + ' img')
  const containerSpacing = getContainerHeight(container);

  let contentHeight = 0;
  for (const x of contentBlocks) {
    contentHeight += getContentHeight(x, containerSpacing)
  }

  container.style.maxHeight = contentHeight + 'px'
}

function getContainerHeight(container) {
  const computedStyle = getComputedStyle(container);
  const gap = parseFloat(computedStyle.getPropertyValue('gap').split(' ')[0])
  const padding = parseFloat(computedStyle.getPropertyValue('padding-block').split(' ')[0])

  return Number(gap + padding);
}

function getContentHeight(content, containerSpacing) {
  const computedStyle = getComputedStyle(content)
  const height = Number(computedStyle.getPropertyValue('height').replace(/px/g, ''))
  const marginHeight = computedStyle.getPropertyValue('margin-block').split(' ').map(parseFloat).reduce((a,b) => a + b, 0)

  return height + marginHeight + containerSpacing;
}
