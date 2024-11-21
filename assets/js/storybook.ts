// If your components require any hooks or custom uploaders, or if your pages
// require connect parameters, uncomment the following lines and declare them as
// such:
//
import Hooks from "./hooks";
import { onInitialPageLoad } from "./src/utils";
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

  onInitialPageLoad(() => {
    const selectedMode = selectedColorMode();
    const actualMode = actualColorMode(selectedMode);
    toggleColorModeClass(actualMode);
    registerThemeSelect();
    registerConsoleLoggerListener();
  });
})();

function registerConsoleLoggerListener() {
  window.addEventListener("storybook:console:log", (info) => {
    console.log(info);
  });
}

function registerThemeSelect() {
  window.addEventListener("psb:set-color-mode", (e) =>
    onSetColorMode(e as CustomEvent)
  );
}

function onSetColorMode(e: CustomEvent) {
  const selectedMode = e.detail.mode || "system";
  const actualMode = actualColorMode(selectedMode);
  toggleColorModeClass(actualMode);
}

function selectedColorMode() {
  return localStorage.getItem("psb_selected_color_mode") || "system";
}

function actualColorMode(selectedMode: string) {
  if (
    selectedMode == "system" &&
    window.matchMedia("(prefers-color-scheme: dark)").matches
  ) {
    return "dark";
  } else if (selectedMode == "dark") {
    return "dark";
  } else {
    return "light";
  }
}

function toggleColorModeClass(mode: "dark" | "light") {
  document.documentElement.dataset.theme = mode;
}
