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

1. **Dark/light toggle only restyles the left-hand strip, not the page.** — **RESOLVED-PENDING-REVIEW (Phase 1, branch `fix/theme-toggle-stable`)**: no-FOUC bootstrap added as the first script in every `<head>`; Tailwind `darkMode: 'class'` config set immediately **after** the CDN `<script>` tag (the Play CDN resets `window.tailwind.config` at load, so pre-CDN config is silently overwritten — post-CDN placement is the documented CDN pattern and raises no ReferenceError); `theme.js` rewritten to toggle `dark` on `<html>` only, wire all toggle buttons via `querySelectorAll` with `aria-pressed` and (emoji-only buttons) `aria-label`, and follow OS preference only when no stored choice exists. Verified page-wide computed-style changes, persistence, CLS 0 and clean console on all five pages (see `docs/phase1-verification.txt`).
   Original finding (confirmed visually in `docs/screenshots/`, dark screenshots: sidebar + top nav darken, main content stays white).
   **Root cause:** in `<head>`, the inline script `tailwind.config = { darkMode: 'class' }` runs **before** `<script src="https://cdn.tailwindcss.com">` loads, so it throws `ReferenceError: tailwind is not defined`. Tailwind therefore runs with its default media-based dark strategy, and toggling the `dark` class on `<html>` never activates the `dark:bg-gray-900` / `dark:text-gray-100` classes on `<body>`. The custom `styles.css` variables only cover the sidebar/nav.
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
| Theme/dark-mode | Known issue 1 — root cause identified (Tailwind config script order) | RESOLVED-PENDING-REVIEW in Phase 1 (`fix/theme-toggle-stable`) |
| Infographic embed | Known issue 2 — `<embed>` of 7.9 MB PDF, fragile on mobile | documented, needs owner decision on approach |
| HTML | Commented-out `research.html` nav link; file absent | documented (no live impact) |
| A11y | Toggle buttons lack `aria-pressed`; 🌙 button unlabeled | documented |
| A11y | Infographic `<embed>` lacks accessible name/alternative | RESOLVED-PENDING-REVIEW: `title="Zambia demographic trends infographic (PDF)"` added in Phase 1 |
| Performance (advisory) | **Tailwind Play CDN (`cdn.tailwindcss.com`) used in production** — ~100 KB runtime compiler JS, console warning, render dependency on a third-party CDN; also the reason dark-mode init must sit after the CDN tag. Owner decision: keep (current policy) or replace with precompiled Tailwind build. NOT removed per standing policy | advisory — keep per policy; revisit only on explicit owner approval |
| A11y (pre-existing, found in Phase 1 full-site axe run) | projects: white text on `bg-orange-500` buttons (~2.8:1, both themes); contact: `text-blue-500` links on white (~3.7:1, light); zambia: download-btn + `.citation-number` orange on white (light), nav/download links in dark | documented — content-level, out of Phase 1 scope; zambia frozen by policy; needs own fix phase |
| Asset size (advisory) | zambia-infographic.pdf 7.9 MB, cv.pdf 2.6 MB, profile.jpg 2.5 MB (also large historical versions) | advisory — keep-all-files policy, owner decision required |
| Broken external links | wikitravel 403, africaportal timeout (both likely bot-blocks) | documented |

| SEO | #5 no meta descriptions on any page | filed (audit) |
| SEO | #6 no Open Graph / Twitter Card tags | filed (audit) |
| SEO | #7 no canonical tags | filed (audit) |
| SEO | #8 sitemap.xml + robots.txt missing (404 live) | filed (audit) |
| SEO | #9 no favicon (404 live, no link rel=icon) | filed (audit) — owner to pick asset |
| Pages | #10 custom 404 disabled; no 404.html | filed (audit) |
| Security | #11 no SRI on CDN scripts — N/A for Play CDN/gtag (dynamic responses); advisory tied to #4 | filed (audit, advisory) |
| A11y | #12 skip-navigation links missing on all 5 pages (WCAG 2.4.1) | filed (audit) |
| Correctness | #13 external links may be dead/hotlink-blocked (wikitravel 403, africaportal timeout) | filed (audit, owner decision) |
| Correctness | #14 two `http://` hrefs on zambia page → https upgrade | filed (audit, needs owner approval — zambia frozen) |
| Performance | #15 asset page weight (profile.jpg 2.47 MB, infographic.png 1.79 MB, embedded PDF 7.89 MB, cv.pdf 2.63 MB) | filed (audit, ADVISORY — owner-gated; options = ADD optimized variants, originals stay) |
| Repo hygiene | #16 README stale/inaccurate (dark-mode issue fixed, wrong clone URL, missing docs/ tree) | filed (audit) |

## Known limitations (owner decisions recorded)

- **`<embed>` of the 7.9 MB infographic PDF is unreliable on iOS Safari / some mobile browsers** (blank render, no fallback message). Owner decision: **KEEP AS IS** — the PNG and PDF download buttons on the page provide alternatives. Do not change without explicit owner approval.
- **External links may be dead or hotlink-blocked** (issue #13): wikitravel 403 and africaportal timeout from automated probes. Owner decides whether to verify manually and update URLs.
- **Tailwind Play CDN in production** (issue #4, SRI advisory #11): owner policy is to KEEP it; it also forces the post-CDN config placement for dark mode (see Decisions).

## Decisions

- 2026-11-10: Safety tag `pre-refactor-2026-11-10` pushed to origin before any branch work.
- 2026-11-10: Baselines captured inside the container via headless Chromium (Playwright `chromium-headless-shell` + locally extracted libs/fonts); Lighthouse run against that binary — real scores, minor caveat that headless-shell rendering may differ slightly from a desktop Chrome.
- 2026-11-10: No code changes in Phase 0b; all findings documented only.
- 2026-11-10 (Phase 1): Tailwind Play CDN resets `window.tailwind.config` at load — dark-mode config must be set **after** the CDN script tag (pre-CDN guarded init is silently overwritten). Verified empirically.
- 2026-11-10 (Phase 1): Emoji-only toggle buttons get `aria-label`; buttons with visible text ("Toggle Dark Mode") keep their visible text as accessible name — overriding it fails axe `label-content-name-mismatch`.
- 2026-11-10 (Phase 1): Tailwind Play CDN rebuilds styles asynchronously after a class toggle — computed-style assertions in tests must allow a short settle time.
- 2026-11-10 (Phase 2): Post-merge production verification PASSED — 44/44 checks (console clean on all 5 pages incl. no `tailwind is not defined`; computed body/main colors flip page-wide on every toggle; persistence + OS-follow OK). Live axe shows only issue-#3 contrast items. No `bug` issues needed. Evidence: `docs/production-verification-phase1.txt`, `docs/production-axe-phase2.txt`, `docs/screenshots/production-post-phase1/`.
- 2026-11-10 (Phase 2): Lighthouse live vs Phase 0b baseline: Perf 90→86 desktop / 94→93 mobile (within run variance + bootstrap script cost), A11y 100→100, BP 96→**100**, SEO 91→91. No regression pattern.
- 2026-11-10 (Phase 2): Secrets sweep (working tree + last 20 commits): clean — only Lighthouse JSON prose false-positives ("password managers" in audit description text). No `target="_blank"` without `rel="noopener"` (all 5 have `noopener noreferrer`). No inline event handlers besides the theme toggles.
- 2026-11-10 (Phase 2): Audit is findings-only — 12 new `audit` issues filed (#5–#16), no code changes.
