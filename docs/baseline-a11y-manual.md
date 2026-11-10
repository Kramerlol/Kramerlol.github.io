# Manual accessibility checklist — baseline 2026-11-10

Checked against https://kramerlol.github.io/ rendered in headless Chromium (fonts + fontconfig provisioned in container). Supplemented by automated axe-core run (`baseline-axe.txt`: 0 violations, WCAG 2.0/2.1 A+AA, both themes, both viewports).

| Item | Result | Notes |
|---|---|---|
| Heading order (one `<h1>` per page, no skipped levels) | PASS | index/about/contact: 1×h1; projects: h1→h2→h3; zambia: h1→h2×6. No level jumps found. |
| `alt` attributes on all images | PARTIAL FAIL | `assets/profile.jpg` on index has `alt="Profile photo"`. The zambia infographic is embedded via `<embed>` (no `img alt`) and has **no accessible name** — a screen reader gets nothing for the page's central artifact. |
| Focus visibility | PASS | No CSS removes outlines; default browser focus rings intact. |
| Toggle keyboard access | PASS | Both toggles are real `<button>` elements with `onclick` — reachable by Tab, activatable with Enter/Space. |
| Toggle `aria-pressed` / state indication | FAIL | Neither the nav 🌙 button nor "Toggle Dark Mode" carries `aria-pressed` or any programmatic state. The 🌙 button's entire label is an emoji (no `aria-label`). |
| Contrast — light theme | PASS | axe color-contrast clean in light theme. |
| Contrast — dark theme | PARTIAL | axe color-contrast clean for the sidebar/nav that actually restyles; the main content does **not** re-theme in dark mode (keeps light colors), so dark-theme contrast is inherited from the light palette — see Known issue 1 in AUDIT.md. |
| Page language | PASS | `<html lang="en">`. |
| Zoom / reflow (390px) | PASS | Layout reflows to single column at ≤700px (media query); nav wraps to second line. |
