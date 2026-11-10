# Site Audit — Kramerlol.github.io

## Overview

Baseline snapshot taken 2026-11-10 at tag `pre-refactor-2026-11-10` (branch `refactor/baseline`). This document is the running audit for the multi-phase refactor. Phase 0b makes **no code changes**.

## Stack

Plain static HTML + CSS + JS, served by GitHub Pages.
- Pages: `index.html`, `about.html`, `projects.html`, `contact.html`, `zambia-demography.html`
- Styling: `styles.css` (CSS variables for theming) **plus Tailwind CSS loaded from CDN at runtime** (`https://cdn.tailwindcss.com` on every page)
- JS: `theme.js` (dark-mode class toggle on `<html>`, persisted in localStorage) + Google `gtag.js` analytics (`G-QNEHHGSYC3`)
- Pages source: branch `main` at `/`, build_type `legacy`, HTTPS enforced, custom 404 off, no CNAME

## Repo policy

- The repository is **public by design** — GitHub Pages user sites require it. Never file "make repo private" issues. The public `cv.pdf` is accepted by the owner (contact info only, no address).
- **Keep-all-files policy**: no existing file may be deleted, renamed, moved, or gitignored — explicitly including `assets/zambia-infographic.pdf`, `assets/zambia-infographic.png`, `cv.pdf`, and `assets/zambia-analysis.R`. Asset size/compression items are **advisory only**; never implemented without explicit owner approval in chat.
- Workflow: feature branches only, never push to main, PRs via `gh pr create`, merge only on explicit owner instruction.

## Known issues (seeded at Phase 0b)

1. **Dark/light toggle only restyles the left-hand strip, not the page.**
   Confirmed visually in `docs/screenshots/` (dark screenshots: sidebar + top nav darken, main content stays white).
   **Root cause identified (investigation, not fixed):** in `<head>`, the inline script `tailwind.config = { darkMode: 'class' }` runs **before** `<script src="https://cdn.tailwindcss.com">` loads, so it throws `ReferenceError: tailwind is not defined`. Tailwind therefore runs with its default media-based dark strategy, and toggling the `dark` class on `<html>` never activates the `dark:bg-gray-900` / `dark:text-gray-100` classes on `<body>`. The custom `styles.css` variables only cover the sidebar/nav.
2. **Infographic PDF inline-display trouble (owner previously switched between PDF and PNG embeds).**
   Current state: `zambia-demography.html` uses `<embed src="assets/zambia-infographic.pdf" type="application/pdf" width="100%" height="900px">`, plus download buttons for both the PNG and PDF. The PDF is **7.9 MB**, so inline `<embed>` rendering is slow/fragile — mobile browsers (iOS Safari) frequently refuse to render embedded PDFs and show a blank/placeholder. Both assets are kept per policy; a future phase should decide the embed approach (e.g., PNG `<img>` display + PDF download link, or `<object>` fallback chain) — decision needed from owner.

## Baseline metrics (2026-11-10)

### HTTP status of all local assets (informational sizes)
| Path | Status | Bytes |
|---|---|---|
| `index.html` | 200 | 3,942 |
| `about.html` | 200 | 2,520 |
| `contact.html` | 200 | 1,754 |
| `projects.html` | 200 | 4,521 |
| `zambia-demography.html` | 200 | 16,059 |
| `styles.css` | 200 | 2,374 |
| `theme.js` | 200 | 472 |
| `cv.pdf` | 200 | 2,625,610 |
| `assets/profile.jpg` | 200 | 2,473,862 |
| `assets/zambia-analysis.R` | 200 | 54,944 |
| `assets/zambia-infographic.pdf` | 200 | 7,893,679 |
| `assets/zambia-infographic.png` | 200 | 1,788,924 |
| `research.html` | **404** | — referenced only inside a **commented-out** nav link (`index.html`); file does not exist in repo |

### Lighthouse (real runs, headless Chromium in container)
| Category | Desktop | Mobile |
|---|---|---|
| Performance | 90 | 94 |
| Accessibility | 100 | 100 |
| Best Practices | 96 | 96 |
| SEO | 91 | 91 |

Key metrics: FCP 2.3 s / LCP 2.3 s / CLS 0 on both form factors; TBT 290 ms (desktop), 150 ms (mobile). Full JSON: `baseline-desktop.json`, `baseline-mobile.json`. Best-practices dings driven by Tailwind CDN production warning + gtag without a consent flow.

### Console errors (see `baseline-console.txt`)
- `ReferenceError: tailwind is not defined` — page error on every page load (inline config script ordering, see Known issue 1).
- `cdn.tailwindcss.com should not be used in production` — console warning (Tailwind Play CDN).

### Links (see `baseline-links.txt`, 33 links scanned)
- **wikitravel.org** `Zambia-regions-map.png` → 403 (hotlink/bot-block — likely fine in a real browser; verify)
- **africaportal.org** SAIIA PDF → connection timeout in linkinator (curl also saw a 301 → follow manually)
- doi.org links returned 403 to curl/headless probes (bot mitigation) but resolve fine in normal browsing — treat as OK.
- No broken internal links except the commented-out `research.html` reference above.

### Accessibility
- axe-core (WCAG 2.x A/AA, injected in both themes, both viewports): **0 violations** — `baseline-axe.txt`
- Manual checklist: `baseline-a11y-manual.md` — fails: infographic `<embed>` has no accessible name; theme toggles lack `aria-pressed` (and the 🌙 button has no text label)

### Screenshots
`docs/screenshots/{desktop,mobile}-{light,dark}.png` (1440×900 / 390×844). Captured in headless Chromium with locally provisioned fonts; they visually confirm Known issue 1.

## Findings log

| Area | Issue# | Status |
|---|---|---|
| Theme/dark-mode | Known issue 1 — root cause identified (Tailwind config script order) | documented, fix in later phase |
| Infographic embed | Known issue 2 — `<embed>` of 7.9 MB PDF, fragile on mobile | documented, needs owner decision on approach |
| HTML | Commented-out `research.html` nav link; file absent | documented (no live impact) |
| A11y | Toggle buttons lack `aria-pressed`; 🌙 button unlabeled | documented |
| A11y | Infographic `<embed>` lacks accessible name/alternative | documented |
| Performance (advisory) | Tailwind Play CDN used in production; ~300 KB runtime JS + warning | advisory |
| Asset size (advisory) | zambia-infographic.pdf 7.9 MB, cv.pdf 2.6 MB, profile.jpg 2.5 MB (also large historical versions) | advisory — keep-all-files policy, owner decision required |
| Broken external links | wikitravel 403, africaportal timeout (both likely bot-blocks) | documented |

## Decisions

- 2026-11-10: Safety tag `pre-refactor-2026-11-10` pushed to origin before any branch work.
- 2026-11-10: Baselines captured inside the container via headless Chromium (Playwright `chromium-headless-shell` + locally extracted libs/fonts); Lighthouse run against that binary — real scores, minor caveat that headless-shell rendering may differ slightly from a desktop Chrome.
- 2026-11-10: No code changes in Phase 0b; all findings documented only.
