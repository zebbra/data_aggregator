import { Hook, makeHook } from "./hook";

// Show appbar border after scrolling down
class MainScrollListener extends Hook {
  mounted(): void {
    const content = document.querySelector("#main-wrapper");
    const appbar = document.querySelector("#appbar");

    if (content && appbar) {
      content.addEventListener("scroll", (event) => {
        const scrollY = (event.target as any)?.scrollTop;
        if (scrollY > 10) {
          appbar.classList.add("shadow-sm", "border-b", "outline");
        } else {
          appbar.classList.remove("shadow-sm", "border-b", "outline");
        }
      });
    }
  }
}

const mainScrollListener = makeHook(MainScrollListener);

export default mainScrollListener;
