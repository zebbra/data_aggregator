import { Hook, makeHook } from "./hook";

// https://blog.ftes.de/phoenix-liveview-headless-ui-b8a0291d4223
// https://github.com/ftes/phoenix-headlessui
class EventBridgeHook extends Hook {
  mounted() {
    // exposes the LiveView JS API to the Web component by
    // binding it to the DOM element as el.__pushEvent

    const target = this.el.attributes["phx-target"]?.value;

    this.el["__pushEvent"] = (
      event: string,
      payload: any,
      onReply: () => {}
    ) => {
      target
        ? this.pushEventTo(target, event, payload, onReply)
        : this.pushEvent(event, payload, onReply);
    };
  }
}

const eventBridgeHook = makeHook(EventBridgeHook);

export default eventBridgeHook;
