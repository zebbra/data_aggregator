import { Hook, makeHook } from "./hook";

class FlashHook extends Hook {
  clearTimeout: number | null = null;

  mounted(): void {
    if (this.el.checkVisibility()) {
      this.maybeStartProgress();
    }
  }

  updated(): void {
    if (this.el.checkVisibility()) {
      this.maybeStartProgress();
    }
  }

  destroyed(): void {
    if (this.clearTimeout) {
      clearTimeout(this.clearTimeout);
      this.clearTimeout = null;
    }
  }

  // Start the progress bar if the flash message has a timeout
  // and a phx-click attribute. Hide the flash message when the
  // progress bar reaches 100%.
  maybeStartProgress() {
    const flash = this.el as HTMLElement;

    const timeout = flash.dataset.timeout;
    if (!timeout) return;

    const cmd = flash.getAttribute("phx-click");
    if (!cmd) return;

    const progress = flash.querySelector(".progress") as HTMLElement;
    if (progress) {
      progress.style.transitionProperty = "width";
      progress.style.width = "100%";
      progress.style.transitionDuration = `${timeout}ms`;
    }

    if (this.clearTimeout) {
      clearTimeout(this.clearTimeout);
      this.clearTimeout = null;
    }

    this.clearTimeout = setTimeout(() => {
      this.liveSocket.execJS(flash, cmd);
    }, parseInt(timeout, 10));
  }
}

const flashHook = makeHook(FlashHook);

export default flashHook;
