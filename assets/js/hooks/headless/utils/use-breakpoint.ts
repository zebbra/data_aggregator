export const BREAKPOINTS = {
  sm: 640,
  md: 768,
  lg: 1024,
  xl: 1280,
  "2xl": 1536,
};

const BREAKPOINT_REGEXP = /^(.*):(.*)$/;

export function visible(breakpoint: string) {
  const match = breakpoint.match(BREAKPOINT_REGEXP);

  if (!match) return false;

  const breakpointWidth = BREAKPOINTS[match[1]] || BREAKPOINTS["lg"];
  const breakpointDirection = match[2] === "hidden" ? "left" : "right";

  if (breakpointDirection === "left") {
    return breakpointWidth > window.innerWidth;
  }

  return breakpointWidth < window.innerWidth;
}
