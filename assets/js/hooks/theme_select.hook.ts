import { Hook, makeHook } from "./hook";

class ThemeSelect extends Hook {
  mounted() {
    this.pushCurrentTheme();
    this.handleEvent("theme:change", ({ theme }) => this.setTheme(theme));
  }

  setTheme(theme: string) {
    this.storeTheme(theme);
    this.applyTheme();
  }

  getTheme() {
    return localStorage.getItem("theme") || "system";
  }

  storeTheme(theme: string) {
    localStorage.setItem("theme", theme);
  }

  applyTheme() {
    const theme = this.getTheme();

    if (theme == "system") {
      document.documentElement.removeAttribute("data-theme");
    } else {
      document.documentElement.setAttribute("data-theme", theme);
    }
  }

  pushCurrentTheme() {
    const theme = this.getTheme();
    this.pushEventTo(this.el, "theme:current", { theme });
  }
}

const themeSelect = makeHook(ThemeSelect);

// apply theme on page load
themeSelect.applyTheme();

export default themeSelect;
