/* global window */
window.addEventListener('scroll', () => {
  const backToTopLink = document.querySelector('.jump-to-top-link');
  const position = window.scrollY;

  position >= 800
    ? backToTopLink.classList.add('visible')
    : backToTopLink.classList.remove('visible');
});
