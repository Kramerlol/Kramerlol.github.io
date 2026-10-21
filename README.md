# Andrew Kramer — Portfolio Website

A lightweight, static personal portfolio built with plain HTML, CSS, and a small amount of JavaScript. The site is hosted on GitHub Pages and showcases research interests, projects, and contact information.

---

## Live Site

🌐 **[https://andrew-kramer.github.io/](https://kramerlol.github.io)**  

---

## Tech Stack

| Layer | Technology |
|---|---|
| Markup | HTML5 |
| Styling | Custom CSS (`styles.css`) + Tailwind CSS via CDN |
| Interactivity | Vanilla JavaScript (`theme.js`) |
| Analytics | Google Analytics 4 (gtag.js) |
| Hosting | GitHub Pages |

---

## Project Structure

```text
.
├── index.html          # Home / landing page with sidebar layout
├── about.html          # Research Interests page
├── projects.html       # Projects portfolio (cards + Shiny app links)
├── contact.html        # Contact page
├── styles.css          # Custom CSS variables, layout, sidebar styling
├── theme.js            # Light / dark mode toggle logic
├── cv.pdf              # Curriculum Vitae (static PDF)
├── assets/
│   └── profile.jpg     # Sidebar profile photo
├── zambia-demography.html   # Detailed Zambia project page
└── README.md           # This file
```

---

## Features

- **Responsive sidebar layout** on the homepage.
- **Project cards** with consistent styling and call-to-action buttons.
- **Embedded R Shiny app links**, e.g. the Preston Curve dashboard.
- **Google Analytics 4 integration** on the homepage (`index.html`) using `gtag.js`.
- **Light / dark mode toggle** (partial — see Known Issues below).

---

## Local Development

No build step is required. To preview locally:

```bash
# Clone the repository
git clone https://github.com/andrew-kramer/andrew-kramer.github.io.git

# Navigate into the folder
cd andrew-kramer.github.io

# Open the site in your default browser
open index.html        # macOS
start index.html       # Windows
```

Or use any static-file server, such as Python’s built-in option:

```bash
python3 -m http.server 8000
# Then visit http://localhost:8000
```

---

## Deployment

This site is designed for **GitHub Pages**:

1. Push all files to the `main` branch of your GitHub repository.
2. In the repository settings, enable **Pages** → source = `Deploy from a branch` → `main` → `/ (root)`.
3. GitHub Pages will serve `index.html` automatically.

> **Note:** If you add a custom domain later, create a `CNAME` file in the repository root containing the domain name.

---

## Google Analytics

The GA4 tag is loaded in `<head>` of `index.html`:

```html
<script async src="https://www.googletagmanager.com/gtag/js?id=G-QNEHHGSYC3"></script>
```

To verify that tracking is active:

1. Open the live site in a browser.
2. Open DevTools → **Network** tab.
3. Filter for `collect` or `google-analytics`.
4. Look for a successful request to `https://www.google-analytics.com/g/collect` containing the Measurement ID.

Real-time dashboard data may take a few minutes to a few hours to appear after first install.

---

## Known Issues

### ⚠️ Dark / light mode toggle does not apply to the entire page

**Current behavior:**  
The theme toggle currently only affects the **left-panel sidebar** on the homepage. The main content area, navbar, and supporting pages (`about.html`, `projects.html`, `contact.html`) do not switch correctly, or do not respond to the toggle at all.

**Likely cause:**  
There is a conflict between two dark-mode implementations:

1. **Custom CSS variables** in `styles.css` rely on `body.dark`.
2. **Tailwind CSS** utility classes (e.g. `dark:bg-gray-900`) rely on `html.dark`, which requires `tailwind.config = { darkMode: 'class' }`.

`theme.js` is not consistently loaded on all pages, and the Tailwind CDN is not configured to use class-based dark mode everywhere.

**Planned fix (TBD):**  
- Unify the toggle logic so `theme.js` adds/removes `dark` on `<html>`.
- Update `styles.css` selectors from `body.dark` to `html.dark`.
- Add the Tailwind `darkMode: 'class'` configuration and load `theme.js` at the bottom of every HTML page.
- Ensure the saved preference persists across pages via `localStorage`.

Until then, the toggle may behave inconsistently.

---

## Roadmap

- [x] Create static portfolio structure
- [x] Add Projects page with R Shiny app links
- [x] Integrate Google Analytics 4
- [ ] Fix light / dark mode toggle sitewide
- [ ] Add more project detail pages
- [ ] Improve mobile responsiveness of the homepage sidebar
- [ ] Add Open Graph / SEO meta tags

---

## License

Content © 2026 Andrew M. Kramer.  
Code in this repository is provided as-is for reference. If you reuse the layout, a credit is appreciated but not required.

---

## Contact

- **Email:** [akramer.pro@proton.me](mailto:akramer.pro@proton.me)
- **LinkedIn:** [linkedin.com/in/andrew-kramer-47346673](https://www.linkedin.com/in/andrew-kramer-47346673/)
- **GitHub:** [github.com/Kramerlol](https://github.com/Kramerlol)
```
