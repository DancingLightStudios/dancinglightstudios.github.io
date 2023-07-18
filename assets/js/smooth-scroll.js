/* global window */
document.querySelectorAll('a[href*="#"]:not([href="#"]):not([href="#0"])').forEach((item) => {
  item.addEventListener('click', (event) => {
    const target = event.srcElement;

    const isOnPage = window.location.pathname.replace(/^\//, '') === event.path.pop().location.pathname.replace(/^\//, '');
    const isSameHost = window.location.hostname === target.hostname;

    if (isOnPage && isSameHost) {
      const jumpToValue = target.getAttribute('href');
      const jumpToTarget = document.getElementById(jumpToValue.substring(1));

      if (jumpToTarget) {
        event.preventDefault();
        jumpToTarget.scrollIntoView({ behavior: 'smooth' });
      }
    }
  });
});
