import { visible } from "./use-breakpoint";

export function useResizeListener(
  close: Function,
  open: Function,
  breakpoint = "lg:hidden",
  delay = 250
) {
  // window.resize callback function
  const resizeFunction = () => {
    const styleAttr = this.el.getAttribute("style");
    const mounted = this.el.getAttribute("phx-mounted");

    // show attribute is dynamic (not used with :if directive)
    const staticMode = this.el.hasAttribute("data-static");

    if (!visible(breakpoint)) {
      if (styleAttr && styleAttr.includes("display: none") === false) {
        close();
      }
    } else if (
      (mounted || !staticMode) &&
      (styleAttr === null || styleAttr.includes("display: none"))
    ) {
      open();
    }
  };

  let timeout: number; // holder for timeout id
  const onResizeHandler = () => {
    // clear the timeout
    clearTimeout(timeout);
    // start timing for event "completion"
    timeout = setTimeout(() => resizeFunction(), delay);
  };

  return onResizeHandler;
}
