function onInitialPageLoad(fn: Function) {
  window.addEventListener("phx:page-loading-stop", (info) => {
    const event = info as CustomEvent;
    if (event.detail.kind !== "initial") return;
    fn(event);
  });
}

const TAILWIND_BREAKPOINTS = {
  xs: 0,
  sm: 640,
  md: 768,
  lg: 1024,
  xl: 1280,
  "2xl": 1536,
  "3xl": 1850,
} as const;

type TAILWIND_BREAKPOINT = keyof typeof TAILWIND_BREAKPOINTS;

function currentScreenSize() {
  const width = window.innerWidth;
  if (width < TAILWIND_BREAKPOINTS["sm"]) {
    return "xs";
  } else if (width < TAILWIND_BREAKPOINTS["md"]) {
    return "sm";
  } else if (width < TAILWIND_BREAKPOINTS["lg"]) {
    return "md";
  } else if (width < TAILWIND_BREAKPOINTS["xl"]) {
    return "lg";
  } else if (width < TAILWIND_BREAKPOINTS["2xl"]) {
    return "xl";
  } else if (width < TAILWIND_BREAKPOINTS["3xl"]) {
    return "2xl";
  } else {
    return "3xl";
  }
}

const debounce = (fn: Function, ms = 300) => {
  let timeoutId: ReturnType<typeof setTimeout>;
  return function (this: any, ...args: any[]) {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn.apply(this, args), ms);
  };
};

export {
  onInitialPageLoad,
  currentScreenSize,
  debounce,
  TAILWIND_BREAKPOINTS,
  type TAILWIND_BREAKPOINT,
};
