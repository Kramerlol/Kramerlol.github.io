# Andrew Kramer — Portfolio Website

A lightweight, static personal portfolio built with plain HTML, CSS, and a small amount of JavaScript, hosted on GitHub Pages: research interests, projects, and contact information.

**Note:** the repository is public **by design** (GitHub Pages user sites require it), and all existing files are kept — no deletions, renames, or moves. See [docs/AUDIT.md](docs/AUDIT.md) for the full audit trail, baselines, and known limitations.

---

## Live Site

🌐 **https://kramerlol.github.io**

---

## Tech Stack

| Layer | Technology |
|---|---|
| Markup | HTML5 |
| Styling | Custom CSS (`styles.css`) + Tailwind CSS via CDN |
| Interactivity | Vanilla JavaScript (`theme.js`) |
| Analytics | Google Analytics 4 (gtag.js) |
| Hosting | GitHub Pages (legacy build, served from `main` at `/`) |

---

## Project Structure

```text
.
├── index.html              # Home / landing page with sidebar layout
├── about.html              # Research Interests
├── projects.html           # Projects portfolio
├── contact.html             # Contact links
├── zambia-demography.html   # Zambia infographic project page
├── 404.html                 # Custom not-found page
├── sitemap.xml / robots.txt # SEO
├── styles.css               # Theme variables, layout, sidebar, skip-link
├── theme.js                 # Whole-page light/dark toggle (html.dark)
├── cv.pdf                   # Curriculum Vitae
├── assets/                  # profile.jpg, favicons, zambia infographic (PDF/PNG) + R analysis
└── docs/                    # Audit trail: baselines, verification evidence, screenshots
```

---

## Local Development

No build step. Clone and preview with any static server:

```bash
git clone https://github.com/Kramerlol/Kramerlol.github.io.git
cd Kramerlol.github.io
python3 -m http.server 8000
# visit http://localhost:8000
```

---

## Deployment

Push to `main` — GitHub Pages auto-deploys to https://kramerlol.github.io (allow up to ~1 minute for builds and CDN cache; hard-refresh if needed).

---

## Theming

Light/dark mode works site-wide: a no-FOUC bootstrap applies the stored theme (or OS preference) on every page, `theme.js` toggles the `dark` class on `<html>`, and Tailwind's class-based dark mode (plus `styles.css` variables) restyles the whole page. The choice persists in `localStorage`.

---

## Roadmap

- [x] Static portfolio structure
- [x] Projects page with R Shiny app links
- [x] Google Analytics 4
- [x] Site-wide light/dark mode toggle
- [x] SEO meta, sitemap, robots.txt, favicon, custom 404, skip links
- [ ] More project detail pages

---

## License

Code is MIT-licensed (see `LICENSE.txt`); content © Andrew M. Kramer.

---

## Contact

- **Email:** [akramer.pro@proton.me](mailto:akramer.pro@proton.me)
- **LinkedIn:** [linkedin.com/in/andrew-kramer-47346673](https://www.linkedin.com/in/andrew-kramer-47346673/)
- **GitHub:** [github.com/Kramerlol](https://github.com/Kramerlol)
