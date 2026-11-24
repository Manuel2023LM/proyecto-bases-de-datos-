(function () {
  var root = document.documentElement;
  var theme = "dark";
  try {
    var saved = window.localStorage.getItem("terra-theme");
    if (saved === "light" || saved === "dark") {
      theme = saved;
    }
  } catch (error) {
    theme = "dark";
  }
  root.dataset.theme = theme;

  function updateThemeButtons() {
    var isDark = root.dataset.theme === "dark";
    document.querySelectorAll("[data-theme-toggle]").forEach(function (button) {
      button.setAttribute("aria-label", isDark ? "Cambiar a modo claro" : "Cambiar a modo oscuro");
      button.setAttribute("aria-pressed", String(isDark));
      var icon = button.querySelector(".theme-icon");
      var label = button.querySelector(".theme-label");
      if (icon) {
        icon.textContent = isDark ? "☀" : "☾";
      }
      if (label) {
        label.textContent = isDark ? "Claro" : "Oscuro";
      }
    });
  }

  document.addEventListener("click", function (event) {
    var button = event.target.closest("[data-theme-toggle]");
    if (!button) {
      return;
    }
    root.dataset.theme = root.dataset.theme === "dark" ? "light" : "dark";
    try {
      window.localStorage.setItem("terra-theme", root.dataset.theme);
    } catch (error) {
      // The selected theme still applies for this page when storage is unavailable.
    }
    updateThemeButtons();
  });

  updateThemeButtons();
})();
