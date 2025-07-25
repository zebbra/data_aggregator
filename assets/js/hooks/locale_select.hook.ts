import { Hook, makeHook } from "./hook";

class LocaleSelect extends Hook {
  mounted() {
    this.el.addEventListener("set-locale", (event) => {
      // reload the page so that all components are re-rendered with the new locale
      const url = new URL(window.location.href);
      url.searchParams.set("locale", (event as CustomEvent).detail);
      location.href = url.toString();
    });
  }
}

const localeSelect = makeHook(LocaleSelect);

export default localeSelect;
