function classNames(...classes: string[]) {
  return classes.filter(Boolean).join(" ");
}

function onInitialPageLoad(fn: Function) {
  window.addEventListener("phx:page-loading-stop", (info) => {
    const event = info as CustomEvent;
    if (event.detail.kind !== "initial") return;
    fn(event);
  });
}

function stringToId(str: string) {
  return str.toLowerCase().replace(/ /g, "_");
}

export { classNames, onInitialPageLoad, stringToId };
