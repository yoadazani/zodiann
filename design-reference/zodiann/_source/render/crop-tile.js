// Crops an app icon to its dark rounded tile on a light background.
// Usage: node crop-tile.js <in.png> <out1.png> [out2.png ...]
const puppeteer = require('puppeteer-core'); const fs = require('fs');
(async () => {
  const [src, ...outs] = process.argv.slice(2);
  const b = await puppeteer.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', args: ['--allow-file-access-from-files'] });
  const p = await b.newPage();
  await p.goto('file:///' + src);
  const r = await p.evaluate(() => {
    const img = document.querySelector('img');
    const W = img.naturalWidth, H = img.naturalHeight, c = document.createElement('canvas'); c.width = W; c.height = H;
    const x = c.getContext('2d'); x.drawImage(img, 0, 0);
    const d = x.getImageData(0, 0, W, H).data;
    const dark = (i, j) => { const k = (j * W + i) * 4; return d[k] + d[k + 1] + d[k + 2] < 200; };
    const mx = W >> 1, my = H >> 1;
    let L = 0, R = W - 1, T = 0, B = H - 1;
    while (!dark(L, my)) L++; while (!dark(R, my)) R--; while (!dark(mx, T)) T++; while (!dark(mx, B)) B--;
    let rr = 0; while (!dark(L + rr, T + rr)) rr++;
    const radius = Math.round(rr / (1 - Math.SQRT1_2));
    const w = R - L + 1, h = B - T + 1, o = document.createElement('canvas'); o.width = w; o.height = h;
    const ox = o.getContext('2d'); ox.beginPath(); ox.roundRect(0, 0, w, h, radius); ox.clip();
    ox.drawImage(img, L, T, w, h, 0, 0, w, h);
    return { W, H, L, R, T, B, radius, data: o.toDataURL('image/png') };
  });
  for (const out of outs) fs.writeFileSync(out, Buffer.from(r.data.split(',')[1], 'base64'));
  delete r.data; console.log(r); await b.close();
})();
