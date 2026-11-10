// Whole-page dark/light theme.
// The 'dark' class is toggled on <html> (documentElement) ONLY — never on
// <body> or a sub-element. Tailwind (darkMode: 'class', configured in each
// page's <head>) and the styles.css `html.dark` rules do the rest.
(function () {
    var html = document.documentElement;
    var mq = window.matchMedia("(prefers-color-scheme: dark)");

    function getStored() {
        try { return localStorage.getItem("theme"); } catch (e) { return null; }
    }

    function syncButtons() {
        var dark = html.classList.contains("dark");
        // Covers every toggle on a page: the nav emoji button, the sidebar
        // .theme-toggle button, and #theme-toggle.
        var buttons = document.querySelectorAll('[onclick*="toggleTheme"]');
        for (var i = 0; i < buttons.length; i++) {
            var b = buttons[i];
            b.setAttribute("aria-pressed", String(dark));
            // Only emoji-only buttons need an aria-label: buttons with visible
            // text (e.g. "Toggle Dark Mode") use that text as their accessible
            // name — overriding it would fail axe's label-content-name-mismatch.
            if (!/\w|\d/.test(b.textContent || "")) {
                b.setAttribute(
                    "aria-label",
                    dark ? "Switch to light mode" : "Switch to dark mode"
                );
            }
        }
    }

    function setTheme(dark, persist) {
        html.classList.toggle("dark", dark);
        if (persist) {
            try { localStorage.setItem("theme", dark ? "dark" : "light"); } catch (e) {}
        }
        syncButtons();
    }

    window.toggleTheme = function () {
        setTheme(!html.classList.contains("dark"), true);
    };

    // Follow OS-level changes only while the visitor has no stored choice.
    if (typeof mq.addEventListener === "function") {
        mq.addEventListener("change", function (e) {
            if (getStored() === null) setTheme(e.matches, false);
        });
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", syncButtons);
    } else {
        syncButtons();
    }
})();
