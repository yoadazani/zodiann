// Usage: node render.js <jobs.json> [filter]
const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../..').split(path.sep).join('/');
const DEVICES = { desktop: [1440, 900, 1], tablet: [834, 1194, 1], 'tablet-land': [1194, 834, 1], mobile: [390, 844, 2], sheet: [1440, 900, 1] };

(async () => {
  const jobs = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const filter = process.argv[3];
  const browser = await puppeteer.launch({
    executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless: true, args: ['--allow-file-access-from-files', '--force-color-profile=srgb', '--font-render-hinting=none'],
  });
  const page = await browser.newPage();
  for (const j of jobs) {
    if (filter && !j.out.includes(filter)) continue;
    const [w, h, dpr] = DEVICES[j.device];
    await page.setViewport({ width: w, height: h, deviceScaleFactor: j.dpr || dpr });
    const url = 'file:///' + ROOT + '/_source/' + j.page + '?' + (j.q || '');
    await page.goto(url, { waitUntil: 'load' });
    await page.evaluate(() => document.fonts.ready);
    await new Promise(r => setTimeout(r, 150));
    const out = path.join(ROOT, j.out);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    if (j.full !== false) {
      const sh = await page.evaluate(() => document.documentElement.scrollHeight);
      await page.setViewport({ width: w, height: Math.max(h, sh), deviceScaleFactor: j.dpr || dpr });
      await new Promise(r => setTimeout(r, 100));
    }
    await page.screenshot({ path: out });
    console.log('ok', j.out);
  }
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
