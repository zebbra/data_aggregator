(() => {
  const w = window;
  const de = document.documentElement;

  type ColorModeColor = "system" | "dark" | "light";

  const knownColorSchemes: Array<ColorModeColor> = ["dark", "light"];

  const options: {
    preference: ColorModeColor;
    fallback: ColorModeColor;
    globalName: string;
    classPrefix: string;
    classSuffix: string;
    storageKey: string;
    dataValue: string;
  } = {
    preference: "system", // default, light, dark, system
    fallback: "light",
    globalName: "ColorMode",
    classPrefix: "",
    classSuffix: "",
    storageKey: "color-mode",
    dataValue: "",
  };

  const preference =
    (window &&
      window.localStorage &&
      window.localStorage.getItem &&
      window.localStorage.getItem(options.storageKey)) ||
    options.preference;

  let value = preference === "system" ? getColorScheme() : preference;

  // Applied forced color mode
  const forcedColorMode = de.getAttribute("data-color-mode-forced");
  if (forcedColorMode) {
    value = forcedColorMode;
  }

  if (["system", "dark", "light"].indexOf(value) === -1) {
    value = options.fallback;
  }

  addColorScheme(value as ColorModeColor);

  function addColorScheme(value: ColorModeColor) {
    const className = `${options.classPrefix}${value}${options.classSuffix}`;

    const dataValue = options.dataValue;
    if (de.classList) {
      de.classList.add(className);
    } else {
      de.className += " " + className;
    }
    if (dataValue) {
      de.setAttribute("data-" + dataValue, value);
    }
  }

  function removeColorScheme(value: ColorModeColor) {
    const className = `${options.classPrefix}${value}${options.classSuffix}`;

    const dataValue = options.dataValue;
    if (de.classList) {
      de.classList.remove(className);
    } else {
      de.className = de.className.replace(new RegExp(className, "g"), "");
    }
    if (dataValue) {
      de.removeAttribute("data-" + dataValue);
    }
  }

  function getColorScheme() {
    // @ts-expect-error matchMedia may not be available
    if (w.matchMedia && prefersColorScheme("").media !== "not all") {
      for (const colorScheme of knownColorSchemes) {
        if (prefersColorScheme(":" + colorScheme).matches) {
          return colorScheme;
        }
      }
    }

    return options.fallback;
  }

  function prefersColorScheme(suffix: string) {
    return w.matchMedia("(prefers-color-scheme" + suffix + ")");
  }

  function toggleColorScheme(preference: ColorModeColor) {
    // Local storage to sync with other tabs
    window.localStorage?.setItem(options.storageKey, preference);

    const value = preference === "system" ? getColorScheme() : preference;

    w[options.globalName].preference = preference;
    w[options.globalName].value = value;

    removeColorScheme("system");
    removeColorScheme("light");
    removeColorScheme("dark");

    addColorScheme(value);
  }

  w[options.globalName] = {
    preference,
    value,
    toggleColorScheme,
  };
})();
