# Zodiann visual design reference

A design-only reference for the Zodiann app. Nothing here is application code.

| Path | Contents |
|---|---|
| `MASTER.md` | The design system: tokens (dark and light), type, spacing, layout per breakpoint, and the exact anatomy of the wheel and the square |
| `DESIGN_DECISIONS.md` | Decisions and their rationale, including the items marked **Needs approval** |
| `screens/` | Desktop (1440 px) mockups of all five screens and the drawer, in English and Hebrew, dark and light |
| `responsive/mobile/` | Phone layouts (390 px @2x): full-page and first-screen captures, the drawer, and all screens |
| `responsive/tablet/` | Tablet portrait (834 px) and landscape (1194 px) layouts |
| `components/` | Component sheet with every state, in dark and light |
| `assets/` | The app logo as SVG with 1024 px PNG renders: the mark without its tile for dark (`zodiann-logo-on-dark`) and a deepened copy for light (`zodiann-logo-on-light`), plus the tiled source and launcher icon (`zodiann-logo`), 33 original icons (SVG), and the open-source fonts used |
| `_source/` | Disposable HTML kit used only to render the PNGs. Do not port it |

File names read `<screen>_<device>_<lang>_<theme>.png`.

**Start with:** `screens/01-zodiac-wheel_desktop_en_dark.png`, `screens/02-square-of-nine_dates_desktop_en_dark.png`, then the same screens in `_he_`, then `responsive/mobile/`.

## Re-rendering

Requires Node and Chrome. Install the renderer once in a scratch folder with `npm i puppeteer-core@23.11.1`, then run `node _source/render/render.js _source/render/jobs.json [name-filter]`. The `ROOT` constant in `render.js` points at this folder.
