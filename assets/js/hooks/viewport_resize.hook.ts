import { debounce } from "./headless/utils/helpers";

let resizeHandler: () => void;

const ViewportResize = {
  destroyed() {
    window.removeEventListener("resize", resizeHandler);
  },
  mounted() {
    // Direct push of current window size to properly update view
    this.pushResizeEvent();

    resizeHandler = debounce(() => this.pushResizeEvent(), 250);
    window.addEventListener("resize", resizeHandler);
  },
  pushResizeEvent() {
    this.pushEvent("viewport_resize", {
      width: window.innerWidth,
      height: window.innerHeight,
    });
  },
};

export default ViewportResize;
