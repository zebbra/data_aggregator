import { ScrollLockStep } from "./overflow-store";

export function adjustScrollbarPadding(): ScrollLockStep {
  let scrollbarWidthBefore: number;

  return {
    before({ doc }) {
      const documentElement = doc.documentElement;
      const ownerWindow = doc.defaultView ?? window;

      scrollbarWidthBefore =
        ownerWindow.innerWidth - documentElement.clientWidth;
    },

    after({ doc, d }) {
      const documentElement = doc.documentElement;

      // Account for the change in scrollbar width
      // NOTE: This is a bit of a hack, but it's the only way to do this
      const scrollbarWidthAfter =
        documentElement.clientWidth - documentElement.offsetWidth;
      const scrollbarWidth = scrollbarWidthBefore - scrollbarWidthAfter;

      d.style(documentElement, "paddingRight", `${scrollbarWidth}px`);
    },
  };
}
