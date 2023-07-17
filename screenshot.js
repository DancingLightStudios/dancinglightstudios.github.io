const HCCrawler = require('headless-chrome-crawler');
const url = require('url');
const slug = require('slug');
const fs = require('fs');

const build = (new Date).getTime();
const PATH = `./screenshots/${build}/`;

fs.existsSync("screenshots") || fs.mkdirSync("screenshots");
fs.existsSync(`${PATH}`) || fs.mkdirSync(`${PATH}`);

(async () => {
  const crawler = await HCCrawler.launch({
    onSuccess: ((result) => {
      console.log(`Screenshot is saved as ${PATH}${result.options.saveAs} for ${result.options.url}.`);
    }),
    preRequest: ((options) => {
      const pageUrl = slug(url.parse(options.url).path, { lower: true });
      options.saveAs = `${pageUrl || (new Date).getTime()}.png`;
      options.screenshot = { path: `${PATH}${options.saveAs}` };
      return true;
    }),
  });
  // saveAs is a custom option for preRequest to conditionally modify options and skip requests
  await crawler.queue({ followSitemapXml: true, url: 'http://127.0.0.1:4000', saveAs: 'test' });
  await crawler.onIdle();
  await crawler.close();
})();
