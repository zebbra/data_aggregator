// If your components require any hooks or custom uploaders, or if your pages
// require connect parameters, uncomment the following lines and declare them as
// such:
//
import Hooks from "./hooks";
// import * as Params from "./params";
// import * as Uploaders from "./uploaders";

declare global {
  interface Window {
    storybook: {
      Hooks: typeof Hooks;
    };
  }
}

(function () {
  // window.storybook = { Hooks, Params, Uploaders };
  window.storybook = { Hooks };

  window.addEventListener("phx:page-loading-stop", (info) => {
    if (initialPageLoad(info as CustomEvent)) {
      const current = currentThemeFromLocation();
      if (current) applyTheme(current);
      registerThemeSelect();
      registerConsoleLoggerListener();
    }
  });
})();

function registerConsoleLoggerListener() {
  window.addEventListener("storybook:console:log", (info) => {
    console.log(info);
  });
}

function initialPageLoad(info: CustomEvent) {
  return info.detail?.kind == "initial";
}

function currentThemeFromLocation() {
  const params = new URLSearchParams(window.location.search);
  return params.get("theme");
}

function registerThemeSelect() {
  const themes = document.getElementsByClassName("psb-theme");

  for (let i = 0; i < themes.length; i++) {
    themes[i].addEventListener("click", (e) => {
      const theme = sanitizeTheme(eventTheme(e));
      applyTheme(theme);
    });
  }
}

function eventTheme(e: Event) {
  return (e.target as any)?.text || (e.target as any)?.innerText;
}

function sanitizeTheme(theme?: string) {
  switch (theme?.trim().toLowerCase()) {
    case "light":
      return "light";
    case "dark":
      return "dark";
    default:
      return "system";
  }
}

function applyTheme(theme: string) {
  if (theme == "system") {
    document.documentElement.removeAttribute("data-theme");
  } else {
    document.documentElement.setAttribute("data-theme", theme);
  }
}
