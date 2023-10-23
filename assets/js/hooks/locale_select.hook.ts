const LocaleSelect = {
  mounted() {
    this.el.addEventListener("set-locale", (event: CustomEvent) => {
      // reload the page so that all components are re-rendered with the new locale
      const url = new URL(window.location.href);
      url.searchParams.set("locale", event.detail);
      location.href = url.toString();
    });
  },
};

export default LocaleSelect;
