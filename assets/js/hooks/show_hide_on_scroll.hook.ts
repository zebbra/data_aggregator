import {
  type TAILWIND_BREAKPOINT,
  TAILWIND_BREAKPOINTS,
  currentScreenSize,
  debounce,
} from "../src/utils";
import { Hook, makeHook } from "./hook";

class ShowHideOnScroll extends Hook {
  private showYNumber: Record<TAILWIND_BREAKPOINT, number>;
  private initialHidden: boolean;
  private duration: number;
  private classList: string[] | undefined;
  private screenSize: string;

  private resizeListener: EventListener;

  mounted(): void {
    const content = document.querySelector("#main_wrapper");

    // early return if the main wrapper is not found
    if (!content) return;

    // we apply the class based on the current screen size (taken from Tailwind's breakpoints)
    this.initializeBreakpoints();

    // update the stored screen size when the window is resized
    this.screenSize = currentScreenSize();
    this.resizeListener = debounce(() => {
      this.screenSize = currentScreenSize();
    });
    window.addEventListener("resize", this.resizeListener);

    const durationMatch = this.el.classList.value.match(/duration-(\d+)/);
    this.duration = durationMatch ? parseInt(durationMatch[1]) : 150;
    this.initialHidden = this.el.classList.contains("hidden");
    this.classList = this.el.dataset.class_list?.split(" ");

    content.addEventListener("scroll", (event) => {
      const scrollY = (event.target as any)?.scrollTop as number;
      this.toggleVisibility(scrollY);
    });
  }

  updated(): void {
    const content = document.querySelector("#main_wrapper");
    if (content) {
      const scrollY = content.scrollTop;
      this.toggleVisibility(scrollY, true);
    }
  }

  destroyed(): void {
    window.removeEventListener("resize", this.resizeListener);
  }

  // we accept either a single number or a comma-separated list of numbers
  // if a single number is provided, it will be used for all breakpoints
  // if a comma-separated list is provided, the first number will be used as the default
  // and the rest will be used for specific breakpoints. if a breakpoint is not provided,
  // the number from the previous breakpoint will be used
  initializeBreakpoints(): void {
    const showY = this.el.dataset.show_y || "0";
    this.showYNumber = {} as Record<TAILWIND_BREAKPOINT, number>;

    if (showY.includes(",")) {
      const breakpoints = showY.split(",");
      const defaultNumber = parseInt(
        breakpoints.find((b) => b.includes(":") === false) || "0"
      );

      // initialize all breakpoints with 0
      Object.keys(TAILWIND_BREAKPOINTS).forEach((key) => {
        this.showYNumber[key as TAILWIND_BREAKPOINT] = 0;
      });

      // set the defined breakpoints
      breakpoints.forEach((b) => {
        if (!b.includes(":")) return;

        const [breakpoint, number] = b.split(":");
        this.showYNumber[breakpoint as TAILWIND_BREAKPOINT] = parseInt(number);
      });

      // for all other breakpoints, use the default number or the previous breakpoint's number
      let previousNumber = defaultNumber;
      Object.keys(TAILWIND_BREAKPOINTS).forEach((key) => {
        if (this.showYNumber[key as TAILWIND_BREAKPOINT] === 0) {
          this.showYNumber[key as TAILWIND_BREAKPOINT] = previousNumber;
        } else {
          previousNumber = this.showYNumber[key as TAILWIND_BREAKPOINT];
        }
      });
    } else {
      const number = parseInt(showY);
      Object.keys(TAILWIND_BREAKPOINTS).forEach((key) => {
        this.showYNumber[key as TAILWIND_BREAKPOINT] = number;
      });
    }
  }

  toggleVisibility(scrollY: number, immediate = false): void {
    if (scrollY > this.showYNumber[this.screenSize]) {
      // only apply the class if it's not already applied
      if (this.el.classList.contains("opacity-0")) {
        if (immediate) {
          this.el.classList.remove("opacity-0");
          this.el.classList.add("opacity-100");
        }

        if (this.initialHidden) {
          this.el.classList.remove("hidden");
        }
        if (this.classList) {
          this.el.classList.remove(...this.classList);
        }

        // first make the element visible and then animate the opacity
        if (!immediate) {
          setTimeout(
            () => {
              this.el.classList.remove("opacity-0");
              this.el.classList.add("opacity-100");
            },
            immediate ? 0 : 10
          );
        }
      }
    } else {
      // only apply the class if it's not already applied
      if (this.el.classList.contains("opacity-100")) {
        this.el.classList.remove("opacity-100");
        this.el.classList.add("opacity-0");

        // wait for the opacity transition to finish before hiding the element
        setTimeout(() => {
          if (this.initialHidden) {
            this.el.classList.add("hidden");
          }
          if (this.classList) {
            this.el.classList.add(...this.classList);
          }
        }, this.duration);
      }
    }
  }
}

const showHideOnScroll = makeHook(ShowHideOnScroll);

export default showHideOnScroll;
