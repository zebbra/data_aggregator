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

    if (!visible(breakpoint)) {
      if (styleAttr && styleAttr.includes("display: none") === false) {
        close();
      }
    } else if (styleAttr === null || styleAttr.includes("display: none")) {
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
