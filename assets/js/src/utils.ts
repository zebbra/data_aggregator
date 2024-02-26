function onInitialPageLoad(fn: Function) {
  window.addEventListener("phx:page-loading-stop", (info) => {
    const event = info as CustomEvent;
    if (event.detail.kind !== "initial") return;
    fn(event);
  });
}

export { onInitialPageLoad };
