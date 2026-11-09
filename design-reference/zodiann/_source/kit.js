/* Zodiann design reference — disposable rendering helpers.
   Generates mockup markup from the spec's real rules (spiral, angles, aspects)
   so the pictures are truthful. Not application code. */

const Q = new URLSearchParams(location.search);
const LANG = Q.get('lang') || 'en';
const THEME = Q.get('theme') || 'dark';
const RTL = LANG === 'he';
document.documentElement.lang = LANG;
document.documentElement.dir = RTL ? 'rtl' : 'ltr';
document.documentElement.dataset.theme = THEME;

/* ---------------- Strings ---------------- */
const HE_ADJ = { 'מערב': 'מערבית', 'צפון-מערב': 'צפון-מערבית', 'צפון': 'צפונית', 'צפון-מזרח': 'צפון-מזרחית', 'מזרח': 'מזרחית', 'דרום-מזרח': 'דרום-מזרחית', 'דרום': 'דרומית', 'דרום-מערב': 'דרום-מערבית' };
const S = {
  en: {
    app: 'Zodiann',
    wheel: 'Zodiac wheel', wheelSub: 'Tropical geocentric positions', wheelDesc: 'Planet positions, aspects and degree crossings',
    square: 'Gann Square of Nine', squareSub: 'Spiral, angles and highlights', squareDesc: 'Numbers, days or 4-hour blocks on the spiral',
    saved: 'Saved squares', savedSub: 'Stored on this device', savedDesc: 'Return to squares you named',
    settings: 'Settings', settingsSub: 'Language, theme, orbs and defaults', settingsDesc: 'Language, theme, orbs, defaults',
    about: 'About and sources', aboutSub: 'Version, sources and method', aboutDesc: 'Computation sources and method',
    tools: 'Analysis', library: 'Library and app',
    version: 'Version 1.0.0', offline: 'All data stays on this device',
    openMenu: 'Open menu',
    rotate: 'Rotate wheel', changeDate: 'Change date',
    rotateHint: 'Drag to turn the wheel. Time stays fixed.',
    underPointer: 'Under the pointer', within3: 'Within 3° of the pointer',
    time: 'Time', dateTime: 'Date and time', now: 'Now', step: 'Step',
    hour: 'Hour', day: 'Day', week: 'Week', d30: '30 days',
    back: 'Back', forward: 'Forward', play: 'Play', localTz: 'Device time, Asia/Jerusalem (UTC+2)',
    positions: 'Positions', positionsMeta: '11 bodies', body: 'Body', sign: 'Sign', position: 'Position', motion: 'Motion',
    direct: 'Direct', retro: 'Retrograde', mean: 'Mean',
    crossings: 'Degree crossings', crossingsCount: '43 crossings', from: 'From', to: 'To', degree: 'Degree',
    allButMoon: 'All except the Moon', anySign: 'Any sign', export: 'Export', localDateTime: 'Local date and time',
    aspects: 'Aspects', conj: 'Conjunction', sextile: 'Sextile', sq: 'Square', trine: 'Trine', opp: 'Opposition',
    mode: 'Mode', numbers: 'Numbers', dates: 'Dates', datetime: 'Date and time',
    anchor: 'Anchor', anchorToday: 'Anchor to today', anchorNow: 'Anchor to now',
    size: 'Size', custom: 'Custom', cells: 'Cells', showToday: 'Show up to today', showNow: 'Show up to now',
    save: 'Save', exportXlsx: 'Export to Excel',
    cellsLine: (n, s) => `${fmtInt(n)} cells, ${s} × ${s}`,
    cell: 'Cell', squared: 'Squared', root: 'Square root', ring: 'Ring', ringCells: (k, c) => `${k} (${c} cells)`,
    angle: 'Angle', direction: 'Direction', offset: 'Offset from center', mult45: 'Multiple of 45°', mult225: 'Multiple of 22.5°',
    yes: 'Yes', no: 'No', highlight: 'Highlight', fromAnchor: 'From the anchor',
    daysAfter: n => `${fmtInt(n)} days after the anchor`, hoursAfter: n => `${fmtInt(n)} hours after the anchor`,
    tagAxis: 'Axis', tagDiag: 'Diagonal', tagEighth: 'Eighth', tagNone: 'No highlight', tagToday: 'Today', tagCenter: 'Center',
    dirAxis: d => `Axis, ${d}`, dirDiag: d => `Diagonal, ${d}`, dirBetween: 'Between the axes and the diagonals',
    W: 'west', NW: 'north-west', N: 'north', NE: 'north-east', E: 'east', SE: 'south-east', S: 'south', SW: 'south-west',
    left: n => `${n} left`, right: n => `${n} right`, up: n => `${n} up`, down: n => `${n} down`, atCenter: 'At the center',
    lineAxis: (a, d) => `Blue: on the ${a}° axis, ${d} of the center`,
    lineDiag: (a, d) => `Yellow: on the ${a}° diagonal, ${d} of the center`,
    lineEighth: a => `Gray: ${a}° is a multiple of 22.5°`,
    lineNone: a => `Not highlighted: ${a}° is not a multiple of 22.5°`,
    lineCenter: 'The center has no angle',
    legendAxis: 'Axes', legendAxisV: '0°, 90°, 180°, 270°', legendDiag: 'Diagonals', legendDiagV: '45°, 135°, 225°, 315°',
    legendEighth: 'Eighths', legendEighthV: 'other multiples of 22.5°', legendCenter: 'Center', legendToday: 'Today', legendSel: 'Selected',
    legendHow: 'Angle = 45° × i ÷ k, where k is the ring and i counts steps clockwise from the axis of cell 2, west of the center.',
    axW: 'W', axN: 'N', axE: 'E', axS: 'S',
    scrollHint: 'Swipe the square sideways',
    // saved
    savedCount: '7 of 100 saved', saveCurrent: 'Save current square', open: 'Open', rename: 'Rename', del: 'Delete', updated: 'Updated',
    // settings
    langRegion: 'Language and region', language: 'Language', system: 'System', dateOrder: 'Date order in English',
    dmy: 'Day/month/year', mdy: 'Month/day/year', timeFormat: 'Time format', h24: '24-hour, in both languages',
    timeZone: 'Time zone', deviceTz: 'Device, Asia/Jerusalem (UTC+2)',
    appearance: 'Appearance', theme: 'Theme', dark: 'Dark', light: 'Light', motionPref: 'Reduced motion', motionPrefV: 'Follows the system setting',
    wheelSettings: 'Wheel and computation', visibleBodies: 'Visible bodies', nodeType: 'Lunar node', nodeMean: 'Mean', nodeTrue: 'True',
    orbs: 'Aspect orbs', orbsHint: 'Allowed deviation from the exact angle', ephemeris: 'Ephemeris source',
    ephSwiss: 'Swiss Ephemeris, data files', ephMoshier: 'Swiss Ephemeris, built-in (Moshier)', ephAE: 'astronomy-engine',
    zodiac: 'Zodiac', tropical: 'Tropical', sidereal: 'Sidereal (planned)', viewpoint: 'Viewpoint', geocentric: 'Geocentric', topocentric: 'Topocentric',
    sqDefaults: 'Square defaults', defMode: 'Default mode', defSize: 'Default size', stepHours: 'Step in date and time mode', stepHoursV: '4 hours',
    data: 'Your data', backupExport: 'Export backup', backupImport: 'Import backup', backupHint: 'One JSON file with your settings and saved squares',
    deleteAll: 'Delete all data', deleteAllHint: 'Removes settings and all saved squares from this device',
    // about
    aboutLead: 'A precise instrument for time cycles: real planet positions on a zodiac wheel, and the Gann Square of Nine where every cell is a number, a day or a 4-hour block.',
    build: 'Build', sources: 'Computation sources', role: 'Role', accuracy: 'Accuracy',
    method: 'Method settings', param: 'Parameter', value: 'Value',
    gannMethod: 'Gann method', disclaimer: 'Not advice',
    disclaimerText: 'Zodiann computes positions and geometry. It does not interpret them, and nothing in the app or its exports is a recommendation to buy or sell.',
    privacy: 'Privacy', privacyText: 'No account, no network access, no analytics. Settings and saved squares stay on this device.',
    licenses: 'Open-source licenses',
  },
  he: {
    app: 'Zodiann',
    wheel: 'גלגל המזלות', wheelSub: 'מיקומים גאוצנטריים טרופיים', wheelDesc: 'מיקומי כוכבים, היבטים ומעברי מעלות',
    square: 'ריבוע התשע של גאן', squareSub: 'ספירלה, זוויות והדגשות', squareDesc: 'מספרים, ימים או בלוקים של 4 שעות בספירלה',
    saved: 'ריבועים שמורים', savedSub: 'שמורים במכשיר הזה', savedDesc: 'חזרה לריבועים ששמרת בשם',
    settings: 'הגדרות', settingsSub: 'שפה, ערכת נושא, אורבים וברירות מחדל', settingsDesc: 'שפה, ערכת נושא, אורבים',
    about: 'אודות ומקורות', aboutSub: 'גרסה, מקורות ושיטה', aboutDesc: 'מקורות החישוב והשיטה',
    tools: 'ניתוח', library: 'ספרייה ואפליקציה',
    version: 'גרסה 1.0.0', offline: 'כל הנתונים נשארים במכשיר',
    openMenu: 'פתיחת תפריט',
    rotate: 'סיבוב הגלגל', changeDate: 'שינוי תאריך',
    rotateHint: 'גוררים כדי לסובב את הגלגל. הזמן לא משתנה.',
    underPointer: 'מתחת למחוג', within3: 'בטווח 3° מהמחוג',
    time: 'זמן', dateTime: 'תאריך ושעה', now: 'עכשיו', step: 'צעד',
    hour: 'שעה', day: 'יום', week: 'שבוע', d30: '30 יום',
    back: 'אחורה', forward: 'קדימה', play: 'ניגון', localTz: 'שעון המכשיר, Asia/Jerusalem (UTC+2)',
    positions: 'מיקומים', positionsMeta: '11 גופים', body: 'גוף', sign: 'מזל', position: 'מיקום', motion: 'תנועה',
    direct: 'ישירה', retro: 'נסיגה', mean: 'ממוצע',
    crossings: 'מעברי מעלות', crossingsCount: '43 מעברים', from: 'מתאריך', to: 'עד תאריך', degree: 'מעלה',
    allButMoon: 'כולם חוץ מהירח', anySign: 'כל המזלות', export: 'ייצוא', localDateTime: 'תאריך ושעה מקומיים',
    aspects: 'היבטים', conj: 'צמידות', sextile: 'סקסטייל', sq: 'ריבוע', trine: 'טריין', opp: 'אופוזיציה',
    mode: 'מצב', numbers: 'מספרים', dates: 'תאריכים', datetime: 'תאריך ושעה',
    anchor: 'עוגן', anchorToday: 'עיגון להיום', anchorNow: 'עיגון לעכשיו',
    size: 'גודל', custom: 'מותאם', cells: 'תאים', showToday: 'הצגה עד היום', showNow: 'הצגה עד עכשיו',
    save: 'שמירה', exportXlsx: 'ייצוא לאקסל',
    cellsLine: (n, s) => `${fmtInt(n)} תאים, ${s} × ${s}`,
    cell: 'תא', squared: 'בריבוע', root: 'שורש ריבועי', ring: 'טבעת', ringCells: (k, c) => `${k} (${c} תאים)`,
    angle: 'זווית', direction: 'כיוון', offset: 'היסט מהמרכז', mult45: 'כפולה של 45°', mult225: 'כפולה של 22.5°',
    yes: 'כן', no: 'לא', highlight: 'הדגשה', fromAnchor: 'מהעוגן',
    daysAfter: n => `${fmtInt(n)} ימים אחרי העוגן`, hoursAfter: n => `${fmtInt(n)} שעות אחרי העוגן`,
    tagAxis: 'ציר', tagDiag: 'אלכסון', tagEighth: 'שמינית', tagNone: 'ללא הדגשה', tagToday: 'היום', tagCenter: 'מרכז',
    dirAxis: d => `ציר, ${d}`, dirDiag: d => `אלכסון, ${d}`, dirBetween: 'בין הצירים לאלכסונים',
    W: 'מערב', NW: 'צפון-מערב', N: 'צפון', NE: 'צפון-מזרח', E: 'מזרח', SE: 'דרום-מזרח', S: 'דרום', SW: 'דרום-מערב',
    left: n => `${n} שמאלה`, right: n => `${n} ימינה`, up: n => `${n} למעלה`, down: n => `${n} למטה`, atCenter: 'במרכז',
    lineAxis: (a, d) => `כחול: על ציר ${a}°, ${HE_ADJ[d]} למרכז`,
    lineDiag: (a, d) => `צהוב: על אלכסון ${a}°, ${HE_ADJ[d]} למרכז`,
    lineEighth: a => `אפור: ${a}° היא כפולה של 22.5°`,
    lineNone: a => `לא מודגש: ${a}° אינה כפולה של 22.5°`,
    lineCenter: 'למרכז אין זווית',
    legendAxis: 'צירים', legendAxisV: '0°, 90°, 180°, 270°', legendDiag: 'אלכסונים', legendDiagV: '45°, 135°, 225°, 315°',
    legendEighth: 'שמיניות', legendEighthV: 'שאר הכפולות של 22.5°', legendCenter: 'מרכז', legendToday: 'היום', legendSel: 'נבחר',
    legendHow: 'זווית = 45° × i ÷ k, כאשר k היא הטבעת ו-i סופר צעדים עם כיוון השעון מהציר של תא 2, ממערב למרכז.',
    axW: 'מע׳', axN: 'צפ׳', axE: 'מז׳', axS: 'דר׳',
    scrollHint: 'מחליקים את הריבוע הצידה',
    savedCount: '7 מתוך 100 שמורים', saveCurrent: 'שמירת הריבוע הנוכחי', open: 'פתיחה', rename: 'שינוי שם', del: 'מחיקה', updated: 'עודכן',
    langRegion: 'שפה ואזור', language: 'שפה', system: 'מערכת', dateOrder: 'סדר התאריך באנגלית',
    dmy: 'יום/חודש/שנה', mdy: 'חודש/יום/שנה', timeFormat: 'תבנית שעה', h24: '24 שעות, בשתי השפות',
    timeZone: 'אזור זמן', deviceTz: 'המכשיר, Asia/Jerusalem (UTC+2)',
    appearance: 'מראה', theme: 'ערכת נושא', dark: 'כהה', light: 'בהירה', motionPref: 'תנועה מופחתת', motionPrefV: 'לפי הגדרת המערכת',
    wheelSettings: 'גלגל וחישוב', visibleBodies: 'גופים מוצגים', nodeType: 'ראש הדרקון', nodeMean: 'ממוצע', nodeTrue: 'אמיתי',
    orbs: 'אורבים להיבטים', orbsHint: 'הסטייה המותרת מהזווית המדויקת', ephemeris: 'מקור האפמריס',
    ephSwiss: 'Swiss Ephemeris, קובצי נתונים', ephMoshier: 'Swiss Ephemeris, מובנה (Moshier)', ephAE: 'astronomy-engine',
    zodiac: 'גלגל מזלות', tropical: 'טרופי', sidereal: 'סידריאלי (מתוכנן)', viewpoint: 'נקודת מבט', geocentric: 'גאוצנטרית', topocentric: 'טופוצנטרית',
    sqDefaults: 'ברירות מחדל לריבוע', defMode: 'מצב ברירת מחדל', defSize: 'גודל ברירת מחדל', stepHours: 'צעד במצב תאריך ושעה', stepHoursV: '4 שעות',
    data: 'הנתונים שלך', backupExport: 'ייצוא גיבוי', backupImport: 'ייבוא גיבוי', backupHint: 'קובץ JSON אחד עם ההגדרות והריבועים השמורים',
    deleteAll: 'מחיקת כל הנתונים', deleteAllHint: 'מוחק מהמכשיר את ההגדרות ואת כל הריבועים השמורים',
    aboutLead: 'כלי מדויק למחזורי זמן: מיקומי כוכבים אמיתיים על גלגל המזלות, וריבוע התשע של גאן שבו כל תא הוא מספר, יום או בלוק של 4 שעות.',
    build: 'בנייה', sources: 'מקורות החישוב', role: 'תפקיד', accuracy: 'דיוק',
    method: 'הגדרות השיטה', param: 'פרמטר', value: 'ערך',
    gannMethod: 'שיטת גאן', disclaimer: 'לא ייעוץ',
    disclaimerText: 'Zodiann מחשבת מיקומים וגאומטריה. היא לא מפרשת אותם, ושום דבר באפליקציה או בקבצים המיוצאים אינו המלצה לקנות או למכור.',
    privacy: 'פרטיות', privacyText: 'בלי חשבון, בלי גישה לרשת ובלי אנליטיקה. ההגדרות והריבועים השמורים נשארים במכשיר.',
    licenses: 'רישיונות קוד פתוח',
  }
};
/* L-7: Latin runs inside Hebrew text are direction-isolated so punctuation stays put. */
const bidi = t => LANG === 'he' && typeof t === 'string' ? t.replace(/\(?[A-Za-z][A-Za-z0-9 .\/()+\-]*[A-Za-z0-9)]/g, m => `<bdi>${m}</bdi>`) : t;
const T = k => bidi(S[LANG][k]);

/* ---------------- Zodiac data ---------------- */
const SIGNS = [
  { k: 'aries', g: '♈', el: 'fire', en: 'Aries', he: 'טלה' },
  { k: 'taurus', g: '♉', el: 'earth', en: 'Taurus', he: 'שור' },
  { k: 'gemini', g: '♊', el: 'air', en: 'Gemini', he: 'תאומים' },
  { k: 'cancer', g: '♋', el: 'water', en: 'Cancer', he: 'סרטן' },
  { k: 'leo', g: '♌', el: 'fire', en: 'Leo', he: 'אריה' },
  { k: 'virgo', g: '♍', el: 'earth', en: 'Virgo', he: 'בתולה' },
  { k: 'libra', g: '♎', el: 'air', en: 'Libra', he: 'מאזניים' },
  { k: 'scorpio', g: '♏', el: 'water', en: 'Scorpio', he: 'עקרב' },
  { k: 'sagittarius', g: '♐', el: 'fire', en: 'Sagittarius', he: 'קשת' },
  { k: 'capricorn', g: '♑', el: 'earth', en: 'Capricorn', he: 'גדי' },
  { k: 'aquarius', g: '♒', el: 'air', en: 'Aquarius', he: 'דלי' },
  { k: 'pisces', g: '♓', el: 'water', en: 'Pisces', he: 'דגים' },
];
/* Sample moment: 9 Nov 2026, 12:00 local. Illustrative positions for the mockup
   (plausible for the date; the app computes them from Swiss Ephemeris). */
const BODIES = [
  { k: 'sun', g: '☉', en: 'Sun', he: 'שמש', lon: 227.05, rx: false },
  { k: 'moon', g: '☽', en: 'Moon', he: 'ירח', lon: 228.69, rx: false },
  { k: 'mercury', g: '☿', en: 'Mercury', he: 'כוכב חמה', lon: 216.20, rx: true },
  { k: 'venus', g: '♀', en: 'Venus', he: 'נוגה', lon: 202.80, rx: true },
  { k: 'mars', g: '♂', en: 'Mars', he: 'מאדים', lon: 138.45, rx: false },
  { k: 'jupiter', g: '♃', en: 'Jupiter', he: 'צדק', lon: 143.60, rx: false },
  { k: 'saturn', g: '♄', en: 'Saturn', he: 'שבתאי', lon: 3.74, rx: true },
  { k: 'uranus', g: '♅', en: 'Uranus', he: 'אורנוס', lon: 61.97, rx: true },
  { k: 'neptune', g: '♆', en: 'Neptune', he: 'נפטון', lon: 359.69, rx: true },
  { k: 'pluto', g: '♇', en: 'Pluto', he: 'פלוטו', lon: 302.87, rx: false },
  { k: 'node', g: '☊', en: 'Mean node', he: 'ראש הדרקון', lon: 326.32, rx: true, node: true },
];
const nm = o => o[LANG];
const vs = g => g + '︎';
const signOf = lon => SIGNS[Math.floor(lon / 30)];
function dm(lon) { const w = lon % 30; const d = Math.floor(w); const m = Math.floor((w - d) * 60); return { d, m }; }
const fmtDM = lon => { const { d, m } = dm(lon); return `${d}°${String(m).padStart(2, '0')}′`; };
const fmtInt = n => n.toLocaleString('en-US');

const ASPECTS = [
  { k: 'conj', a: 0, orb: 8, c: 'conj', g: '☌' },
  { k: 'sextile', a: 60, orb: 4, c: 'soft', g: '⚹' },
  { k: 'sq', a: 90, orb: 6, c: 'hard', g: '□' },
  { k: 'trine', a: 120, orb: 6, c: 'soft', g: '△' },
  { k: 'opp', a: 180, orb: 8, c: 'hard', g: '☍' },
];
function aspectsOf(bodies) {
  const out = [];
  const bs = bodies.filter(b => !b.node);
  for (let x = 0; x < bs.length; x++) for (let y = x + 1; y < bs.length; y++) {
    let d = Math.abs(((bs[x].lon - bs[y].lon + 540) % 360) - 180);
    const hit = ASPECTS.find(a => Math.abs(d - a.a) <= a.orb);
    if (hit) out.push({ a: bs[x], b: bs[y], t: hit });
  }
  return out;
}

/* ---------------- Icons (24px grid, 1.6 stroke) ---------------- */
const IC = {
  menu: '<path d="M4 7h16M4 12h16M4 17h16"/>',
  x: '<path d="M6 6l12 12M18 6L6 18"/>',
  chevL: '<path d="M14.5 6l-6 6 6 6"/>', chevR: '<path d="M9.5 6l6 6-6 6"/>', chevD: '<path d="M7 10l5 5 5-5"/>',
  play: '<path d="M9 6.5v11l9-5.5z" fill="currentColor" stroke="none"/>',
  pause: '<path d="M8.5 6h2.5v12H8.5zM13 6h2.5v12H13z" fill="currentColor" stroke="none"/>',
  calendar: '<rect x="4" y="5.5" width="16" height="14.5" rx="2"/><path d="M4 10h16M9 3.5v4M15 3.5v4"/>',
  clock: '<circle cx="12" cy="12" r="8"/><path d="M12 7.5V12l3 2"/>',
  download: '<path d="M12 4v11M7.5 10.5L12 15l4.5-4.5M5 19.5h14"/>',
  upload: '<path d="M12 15.5v-11M7.5 9L12 4.5 16.5 9M5 19.5h14"/>',
  save: '<path d="M7 4h10v16l-5-4-5 4z"/>',
  wheel: '<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="5"/><path d="M12 3.5V7M12 17v3.5M3.5 12H7M17 12h3.5M6 6l2.5 2.5M15.5 15.5L18 18M18 6l-2.5 2.5M8.5 15.5L6 18"/>',
  grid: '<rect x="4" y="4" width="16" height="16" rx="1.5"/><path d="M9.33 4v16M14.67 4v16M4 9.33h16M4 14.67h16"/>',
  folder: '<path d="M3.5 7.5a2 2 0 012-2h3.8l2 2h7.2a2 2 0 012 2v7.5a2 2 0 01-2 2h-13a2 2 0 01-2-2z"/>',
  sliders: '<path d="M4 7h9M17 7h3M4 17h3M11 17h9"/><circle cx="15" cy="7" r="2"/><circle cx="9" cy="17" r="2"/>',
  info: '<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5.5M12 7.8v.4"/>',
  trash: '<path d="M4.5 7h15M9.5 7V4.5h5V7M6.5 7l1 13h9l1-13M10 11v5.5M14 11v5.5"/>',
  target: '<circle cx="12" cy="12" r="6.5"/><circle cx="12" cy="12" r="1.5" fill="currentColor"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3"/>',
  anchor: '<circle cx="12" cy="5.5" r="2"/><path d="M12 7.5V20M5 13a7 7 0 0014 0M9 10.5h6"/>',
  pencil: '<path d="M4.5 19.5h4l10-10-4-4-10 10z"/>',
  more: '<circle cx="12" cy="5.5" r="1.3" fill="currentColor"/><circle cx="12" cy="12" r="1.3" fill="currentColor"/><circle cx="12" cy="18.5" r="1.3" fill="currentColor"/>',
  rotate: '<path d="M19.5 12a7.5 7.5 0 11-2.2-5.3M19.5 4.5v4h-4"/>',
  datewheel: '<path d="M19.5 12a7.5 7.5 0 11-2.2-5.3M19.5 4.5v4h-4"/><path d="M12 9v3.5l2 1.5"/>',
  alert: '<path d="M12 4l9 15.5H3z"/><path d="M12 10v4M12 16.8v.4"/>',
  check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2.5M12 19v2.5M2.5 12H5M19 12h2.5M5.3 5.3l1.8 1.8M16.9 16.9l1.8 1.8M18.7 5.3l-1.8 1.8M7.1 16.9l-1.8 1.8"/>',
  moon: '<path d="M19 14.5A7.5 7.5 0 019.5 5a7.5 7.5 0 109.5 9.5z"/>',
  globe: '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.5 2.3 3.5 5.3 3.5 8.5s-1 6.2-3.5 8.5c-2.5-2.3-3.5-5.3-3.5-8.5s1-6.2 3.5-8.5z"/>',
  book: '<path d="M5 4.5h10a3 3 0 013 3v12H8a3 3 0 01-3-3z"/><path d="M5 16.5a3 3 0 013-3h10"/>',
  shield: '<path d="M12 3.5l7 3v5.5c0 4.2-3 7.3-7 8.5-4-1.2-7-4.3-7-8.5V6.5z"/><path d="M9 12l2 2 4-4"/>',
  copy: '<rect x="8" y="8" width="11.5" height="11.5" rx="2"/><path d="M15.5 8V6a1.5 1.5 0 00-1.5-1.5H6A1.5 1.5 0 004.5 6v8A1.5 1.5 0 006 15.5h2"/>',
  file: '<path d="M7 3.5h7l4.5 4.5v12.5H7z"/><path d="M14 3.5V8h4.5"/>',
};
const icon = (n, cls = '') => `<svg class="i ${cls}" viewBox="0 0 24 24" aria-hidden="true">${IC[n]}</svg>`;
/* For the directional chevrons: back/forward point with the reading direction. */
const iconBack = () => icon(RTL ? 'chevR' : 'chevL');
const iconFwd = () => icon(RTL ? 'chevL' : 'chevR');

/* ---------------- Brand logo ---------------- */
/* The app icon from the specification is the logo everywhere. */
function markSVG(size = 32) {
  /* Tile removed in both themes so the mark sits directly on the panel;
     the light theme uses a deepened copy with dark empty cells so it reads on white. */
  return `<img class="logo" src="../assets/zodiann-logo-on-${THEME === 'dark' ? 'dark' : 'light'}.svg" width="${size}" height="${size}" alt="" style="display:block;flex:none">`;
}

/* ---------------- Shell ---------------- */
const NAV = [
  { k: 'wheel', i: 'wheel' }, { k: 'square', i: 'grid' }, null,
  { k: 'saved', i: 'folder' }, { k: 'settings', i: 'sliders' }, { k: 'about', i: 'info' },
];
function drawerHTML(active) {
  const items = NAV.map(n => n === null ? `<div class="nav-group">${T('library')}</div>` :
    `<div class="nav-item ${n.k === active ? 'on' : ''}">${icon(n.i)}<span class="name">${T(n.k)}</span><span class="desc">${T(n.k + 'Desc')}</span></div>`).join('');
  return `<div class="scrim"></div><aside class="drawer">
    <div class="drawer-head"><div class="brand">${markSVG(40)}<span class="word">Zodiann</span></div>
      <button class="icon-btn">${icon('x')}</button></div>
    <nav><div class="nav-group" style="padding-top:var(--s2)">${T('tools')}</div>${items}</nav>
    <div class="drawer-foot"><span>${T('version')}</span><span>${T('offline')}</span></div></aside>`;
}
function shell({ screen, end = '', body }) {
  const drawer = Q.get('drawer') === '1';
  document.body.innerHTML = `<div class="app">
    <header class="topbar">
      <button class="icon-btn" aria-label="${T('openMenu')}">${icon('menu')}</button>
      <div class="titles"><h1>${T(screen)}</h1><div class="sub">${T(screen + 'Sub')}</div></div>
      <div class="end">${end}</div>
    </header>
    <main class="content">${body}</main>
    ${drawer ? drawerHTML(screen) : ''}
  </div>`;
}

/* ---------------- Zodiac wheel ---------------- */
function spreadDisplay(bodies, minSep) {
  const items = bodies.map(b => ({ b, a: b.lon }));
  for (let it = 0; it < 400; it++) {
    items.sort((p, q) => p.a - q.a);
    let moved = false;
    for (let i = 0; i < items.length; i++) {
      const p = items[i], q = items[(i + 1) % items.length];
      let gap = (q.a - p.a + 360) % 360;
      if (gap < minSep) { const push = (minSep - gap) / 2 + .01; p.a = (p.a - push + 360) % 360; q.a = (q.a + push) % 360; moved = true; }
    }
    if (!moved) break;
  }
  const m = new Map(); items.forEach(x => m.set(x.b.k, x.a)); return m;
}
function wheelSVG({ pointerLon = BODIES[0].lon, focus = false, compact = false } = {}) {
  /* compact: the phone wheel. Same geometry, larger glyphs and wider spacing so
     marks stay >= 12px when the wheel is ~340px wide. */
  const R = 300, rSignOut = 296, rSignIn = compact ? 240 : 250, rTick = rSignIn, rNum = rSignIn - 26, rBody = compact ? 180 : 192, rBodyDeg = compact ? 140 : 164, rInner = compact ? 112 : 136;
  const sz = compact ? { glyph: 27, sign: 30, deg: 19, dl: 14, r: 21, sep: 16 } : { glyph: 17, sign: 21, deg: 11.5, dl: 9.5, r: 14, sep: 11 };
  const ang = lon => (90 + (lon - pointerLon)) * Math.PI / 180;
  const P = (lon, r) => [r * Math.cos(ang(lon)), -r * Math.sin(ang(lon))];
  const f = v => v.toFixed(2);
  let s = `<svg class="wheel" viewBox="-322 -334 644 656" direction="ltr" role="img">`;
  // sign sectors
  SIGNS.forEach((sg, i) => {
    const a0 = i * 30, a1 = a0 + 30;
    const [x0, y0] = P(a0, rSignOut), [x1, y1] = P(a1, rSignOut), [x2, y2] = P(a1, rSignIn), [x3, y3] = P(a0, rSignIn);
    s += `<path d="M${f(x0)} ${f(y0)} A${rSignOut} ${rSignOut} 0 0 0 ${f(x1)} ${f(y1)} L${f(x2)} ${f(y2)} A${rSignIn} ${rSignIn} 0 0 1 ${f(x3)} ${f(y3)}Z" style="fill:var(--${sg.el});fill-opacity:var(--sign-tint)"/>`;
    const [gx, gy] = P(a0 + 15, (rSignOut + rSignIn) / 2);
    s += `<text class="sign-glyph" x="${f(gx)}" y="${f(gy)}" style="fill:var(--${sg.el});font-size:${sz.sign}px">${vs(sg.g)}</text>`;
    const [sx0, sy0] = P(a0, rSignOut), [sx1, sy1] = P(a0, rTick - 18);
    s += `<line class="sep" x1="${f(sx0)}" y1="${f(sy0)}" x2="${f(sx1)}" y2="${f(sy1)}"/>`;
  });
  s += `<circle class="frame accent" r="${rSignOut}"/><circle class="frame" r="${rSignIn}"/><circle class="frame" r="${R + 6}" style="opacity:.5"/>`;
  // degree ticks
  for (let d = 0; d < 360; d++) {
    if (d % 30 === 0) continue;
    const len = d % 10 === 0 ? 14 : d % 5 === 0 ? 9 : 5;
    const [x0, y0] = P(d, rTick), [x1, y1] = P(d, rTick - len);
    s += `<line class="tick ${d % 10 === 0 ? 't10' : d % 5 === 0 ? 't5' : ''}" x1="${f(x0)}" y1="${f(y0)}" x2="${f(x1)}" y2="${f(y1)}"/>`;
    if (d % 10 === 0) { const [tx, ty] = P(d, rNum); s += `<text class="deg-lbl" x="${f(tx)}" y="${f(ty)}" style="font-size:${sz.dl}px">${d % 30}</text>`; }
  }
  s += `<circle class="inner" r="${rInner}"/>`;
  // aspects
  aspectsOf(BODIES).forEach(({ a, b, t }) => {
    const [x0, y0] = P(a.lon, rInner), [x1, y1] = P(b.lon, rInner);
    s += `<line class="asp ${t.c}" x1="${f(x0)}" y1="${f(y0)}" x2="${f(x1)}" y2="${f(y1)}"/>`;
  });
  // bodies
  const disp = spreadDisplay(BODIES, sz.sep);
  BODIES.forEach(b => {
    const da = disp.get(b.k), col = `var(--b-${b.k})`;
    const [ex, ey] = P(b.lon, rTick - 1), [cx0, cy0] = P(da, rBody + sz.r + 1);
    const [bx, by] = P(da, rBody), [dx, dy] = P(da, rBodyDeg), [ix, iy] = P(b.lon, rInner);
    s += `<line class="connector" x1="${f(ex)}" y1="${f(ey)}" x2="${f(cx0)}" y2="${f(cy0)}" style="stroke:${col}"/>`;
    s += `<circle class="body-bg" cx="${f(bx)}" cy="${f(by)}" r="${sz.r}" style="stroke:${col}"/>`;
    s += `<text class="body-glyph" x="${f(bx)}" y="${f(by) - .5}" style="fill:${col};font-size:${sz.glyph}px">${vs(b.g)}</text>`;
    s += `<text class="body-deg" x="${f(dx)}" y="${f(dy)}" style="font-size:${sz.deg}px">${dm(b.lon).d}°${b.rx && !b.node ? '<tspan class="rx">℞</tspan>' : ''}</text>`;
    s += `<circle cx="${f(ix)}" cy="${f(iy)}" r="${compact ? 4.5 : 3.2}" style="fill:${col}"/>`;
  });
  // fixed pointer at the top (WH-7)
  s += `<line class="pointer-line" x1="0" y1="${-rSignOut}" x2="0" y2="${-(rTick - 18)}"/>`;
  s += `<path class="pointer" d="M-9 -330 L9 -330 L0 -312 Z"/>`;
  s += `<circle class="hub" r="2.5"/>`;
  if (focus) s += `<circle class="focus-ring" r="${R + 14}"/>`;
  return s + '</svg>';
}

/* ---------------- Gann Square of Nine (spec: Gann spiral) ---------------- */
function ringOf(n) { return n === 1 ? 0 : Math.ceil((Math.sqrt(n) - 1) / 2); }
function cellXY(n) {
  if (n === 1) return { x: 0, y: 0 };
  const k = ringOf(n), j = n - (2 * k - 1) ** 2 - 1;
  let x, y;
  if (j < 2 * k) { x = k; y = j - k + 1; }
  else if (j < 4 * k) { x = 3 * k - 1 - j; y = k; }
  else if (j < 6 * k) { x = -k; y = 5 * k - 1 - j; }
  else { x = j - 7 * k + 1; y = -k; }
  return { x: -x, y: -y };
}
function cellInfo(n) {
  if (n === 1) return { n, k: 0, i: null, angle: null, hl: 'center', ...cellXY(1) };
  const k = ringOf(n), j = n - (2 * k - 1) ** 2 - 1;
  const i = (((j - (k - 1)) % (8 * k)) + 8 * k) % (8 * k);
  const angle = 45 * i / k;
  const hl = i % (2 * k) === 0 ? 'axis' : i % k === 0 ? 'diag' : (2 * i) % k === 0 ? 'eighth' : 'none';
  return { n, k, i, angle, hl, ...cellXY(n) };
}
const COMPASS = { 0: 'W', 45: 'NW', 90: 'N', 135: 'NE', 180: 'E', 225: 'SE', 270: 'S', 315: 'SW' };
const fmtAngle = a => (Number.isInteger(a) ? a : +a.toFixed(2)) + '°';

function addDays(d, n) { return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n, d.getHours(), d.getMinutes()); }
function addHours(d, h) { return new Date(d.getTime() + h * 3600e3); }
const fmtShort = d => `${d.getDate()}.${d.getMonth() + 1}.${String(d.getFullYear() % 100).padStart(2, '0')}`;
const fmtHM = d => `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
const fmtLong = (d, withTime) => {
  const loc = LANG === 'he' ? 'he-IL' : 'en-GB';
  const s = new Intl.DateTimeFormat(loc, { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }).format(d);
  return withTime ? `${s}, ${fmtHM(d)}` : s;
};
const NOW = new Date(2026, 10, 9, 12, 0);

function squareModel({ mode = 'dates', side = 17, anchor = new Date(2026, 3, 15), stepH = 4 }) {
  const valueOf = n => mode === 'numbers' ? n : mode === 'dates' ? addDays(anchor, n - 1) : addHours(anchor, stepH * (n - 1));
  let today = null;
  if (mode === 'dates') today = Math.round((new Date(NOW.getFullYear(), NOW.getMonth(), NOW.getDate()) - new Date(anchor.getFullYear(), anchor.getMonth(), anchor.getDate())) / 864e5) + 1;
  if (mode === 'datetime') today = Math.floor((NOW - anchor) / (stepH * 3600e3)) + 1;
  return { mode, side, anchor, stepH, valueOf, today, total: side * side };
}
function cellLabel(m, n) {
  const v = m.valueOf(n);
  if (m.mode === 'numbers') return fmtInt(v);
  if (m.mode === 'dates') return fmtShort(v);
  return `${fmtShort(v)}<span class="t">${fmtHM(v)}</span>`;
}
const MARK = { axis: '+', diag: '×' };
function squareHTML(m, { cell = 52, sel = null, labels = true, font = null } = {}) {
  const h = (m.side - 1) / 2, grid = [];
  for (let n = 1; n <= m.total; n++) { const c = cellInfo(n); grid[(c.y + h) * m.side + (c.x + h)] = c; }
  const cells = grid.map(c => {
    const cls = ['cell', c.hl !== 'none' && c.hl !== 'center' ? c.hl : '', c.n === 1 ? 'center' : '', c.n === m.today ? 'today' : '', c.n === sel ? 'sel' : ''].join(' ');
    const mk = MARK[c.hl] ? `<span class="mk">${MARK[c.hl]}</span>` : '';
    return `<div class="${cls}">${mk}<span>${cellLabel(m, c.n)}</span></div>`;
  }).join('');
  const sq = `<div class="sq" style="grid-template-columns:repeat(${m.side},${cell}px);grid-auto-rows:${cell}px;${font ? `font-size:${font}px` : ''}">${cells}</div>`;
  if (!labels) return sq;
  const ax = (k, deg, cls = '') => `<div class="ax ${cls}"><span><b>${deg}</b> ${T(k)}</span></div>`;
  return `<div class="sq-frame"><div></div>${ax('axN', '90°')}<div></div>${ax('axW', '0°', 'v l')}${sq}${ax('axE', '180°', 'v')}<div></div>${ax('axS', '270°')}<div></div></div>`;
}
function miniSquare(side, px, extra = {}) {
  const h = (side - 1) / 2, g = [];
  for (let n = 1; n <= side * side; n++) { const c = cellInfo(n); g[(c.y + h) * side + (c.x + h)] = c; }
  return `<div class="mini" style="grid-template-columns:repeat(${side},1fr);width:${px}px">${g.map(c => `<i class="${c.n === 1 ? 'center' : c.n === extra.today ? 'today' : c.hl}"></i>`).join('')}</div>`;
}
function cellDetails(m, n) {
  const c = cellInfo(n);
  const tagKey = { axis: 'tagAxis', diag: 'tagDiag', eighth: 'tagEighth', none: 'tagNone', center: 'tagCenter' }[c.hl];
  const markG = MARK[c.hl] ? `<span class="mk">${MARK[c.hl]}</span>` : '';
  const tags = `<span class="tag ${c.hl}">${markG}${T(tagKey)}</span>${n === m.today ? `<span class="tag today">${T('tagToday')}</span>` : ''}`;
  const off = [];
  if (c.x) off.push(c.x < 0 ? S[LANG].left(-c.x) : S[LANG].right(c.x));
  if (c.y) off.push(c.y < 0 ? S[LANG].up(-c.y) : S[LANG].down(c.y));
  const dirName = COMPASS[c.angle] ? T(COMPASS[c.angle]) : null;
  const direction = c.hl === 'center' ? '—' : c.hl === 'axis' ? S[LANG].dirAxis(dirName) : c.hl === 'diag' ? S[LANG].dirDiag(dirName) : T('dirBetween');
  const line = c.hl === 'center' ? T('lineCenter') : c.hl === 'axis' ? S[LANG].lineAxis(c.angle, dirName) : c.hl === 'diag' ? S[LANG].lineDiag(c.angle, dirName)
    : c.hl === 'eighth' ? S[LANG].lineEighth(fmtAngle(c.angle).replace('°', '')) : S[LANG].lineNone(fmtAngle(c.angle).replace('°', ''));
  let dateBlock = '';
  if (m.mode !== 'numbers') {
    const v = m.valueOf(n);
    const dist = m.mode === 'dates' ? S[LANG].daysAfter(n - 1) : S[LANG].hoursAfter(m.stepH * (n - 1));
    dateBlock = `<div class="det-date"><div class="det-date-main">${fmtLong(v, m.mode === 'datetime')}</div><div class="hint">${dist}</div></div>`;
  }
  const yes = b => b ? T('yes') : T('no');
  return { c, tags, dateBlock, line, rows: [
    [T('squared'), `<span class="num">${fmtInt(n)}² = ${fmtInt(n * n)}</span>`],
    [T('root'), `<span class="num">√${fmtInt(n)} = ${Math.sqrt(n).toFixed(4)}</span>`],
    [T('ring'), c.k ? S[LANG].ringCells(c.k, 8 * c.k) : '—'],
    [T('angle'), c.angle === null ? '—' : `<span class="num">${fmtAngle(c.angle)}</span>`],
    [T('direction'), direction],
    [T('offset'), off.length ? off.join(', ') : T('atCenter')],
    [T('mult45'), c.angle === null ? '—' : yes(c.angle % 45 === 0)],
    [T('mult225'), c.angle === null ? '—' : yes(c.angle % 22.5 === 0)],
  ] };
}
function legendHTML() {
  return `<div class="legend">
    <span class="it"><span class="sw axis">+</span><b>${T('legendAxis')}</b> <span class="num">${T('legendAxisV')}</span></span>
    <span class="it"><span class="sw diag">×</span><b>${T('legendDiag')}</b> <span class="num">${T('legendDiagV')}</span></span>
    <span class="it"><span class="sw eighth"></span><b>${T('legendEighth')}</b> ${T('legendEighthV')}</span>
    <span class="it"><span class="sw center"></span>${T('legendCenter')}</span>
    <span class="it"><span class="sw today"></span>${T('legendToday')}</span>
    <span class="it"><span class="sw sel"></span>${T('legendSel')}</span>
  </div><p class="hint" style="margin-top:var(--s3)">${T('legendHow')}</p>`;
}

/* ---------------- Crossing sample rows (0° of any sign, next 12 months) ---------------- */
const CROSSINGS = [
  ['22.11.26', '07:36', 'sun', 8, false], ['25.11.26', '14:12', 'mars', 5, false], ['4.12.26', '19:05', 'mercury', 8, false],
  ['6.12.26', '03:40', 'venus', 7, false], ['21.12.26', '22:50', 'sun', 9, false], ['23.12.26', '11:27', 'mercury', 9, false],
  ['3.1.27', '16:18', 'venus', 8, false], ['11.1.27', '08:53', 'mercury', 10, false], ['20.1.27', '09:29', 'sun', 10, false],
  ['26.1.27', '21:04', 'neptune', 0, false], ['29.1.27', '02:47', 'venus', 9, false], ['1.2.27', '05:15', 'mercury', 11, false],
  ['13.2.27', '18:22', 'mars', 5, true], ['14.2.27', '23:40', 'mercury', 11, true], ['18.2.27', '23:33', 'sun', 11, false],
  ['22.2.27', '10:08', 'venus', 10, false],
];
const bodyBy = k => BODIES.find(b => b.k === k);
