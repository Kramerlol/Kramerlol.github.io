// Load stored preference, fallback to system preference
const savedTheme = localStorage.getItem("theme");
const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;

if (savedTheme === "dark" || (!savedTheme && prefersDark)) {
    document.body.classList.add("dark");
    document.documentElement.classList.add("dark");
}

function toggleTheme() {
    document.body.classList.toggle("dark");
    document.documentElement.classList.toggle("dark");

    // Save preference
    const isDark = document.body.classList.contains("dark");
    localStorage.setItem("theme", isDark ? "dark" : "light");
}
