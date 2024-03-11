import { Hook, makeHook } from "./hook";

// Show appbar border after scrolling down
class MainScrollListener extends Hook {
  private appbar: HTMLElement | null;

  mounted(): void {
    const content = document.querySelector("#main_wrapper");
    this.appbar = document.querySelector("#appbar");

    if (content && this.appbar) {
      content.addEventListener("scroll", (event) => {
        const scrollY = (event.target as any)?.scrollTop;
        this.toggleVisibility(scrollY);
      });
    }
  }

  updated(): void {
    const content = document.querySelector("#main_wrapper");
    if (content && this.appbar) {
      const scrollY = content.scrollTop;
      this.toggleVisibility(scrollY);
    }
  }

  toggleVisibility(scrollY: number): void {
    if (this.appbar) {
      if (scrollY > 10) {
        if (this.appbar.classList.contains("shadow-sm") === false) {
          this.appbar.classList.add("shadow-sm", "border-b");
        }
      } else {
        if (this.appbar.classList.contains("shadow-sm")) {
          this.appbar.classList.remove("shadow-sm", "border-b");
        }
      }
    }
  }
}

const mainScrollListener = makeHook(MainScrollListener);

export default mainScrollListener;
