// Export the icon set as standalone SVG files.
const puppeteer = require('puppeteer-core'); const fs = require('fs');
const A = require('path').resolve(__dirname, '../../assets').split(require('path').sep).join('/');
(async () => {
  const b = await puppeteer.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', args: ['--allow-file-access-from-files'] });
  const p = await b.newPage();
  await p.goto('file:///' + A.replace('/assets', '') + '/_source/components.html', { waitUntil: 'load' });
  const r = await p.evaluate(() => ({ icons: IC }));
  for (const [k, v] of Object.entries(r.icons))
    fs.writeFileSync(`${A}/icons/${k}.svg`, `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">${v}</svg>\n`);
  await b.close(); console.log(Object.keys(r.icons).length, 'icons');
})();
