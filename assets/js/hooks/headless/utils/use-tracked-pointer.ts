import { ref } from "@vue/reactivity";

type PointerPosition = [x: number, y: number];

function eventToPosition(evt: PointerEvent): PointerPosition {
  return [evt.screenX, evt.screenY];
}

export function useTrackedPointer() {
  const lastPos = ref<PointerPosition>([-1, -1]);

  return {
    wasMoved(evt: PointerEvent) {
      const newPos = eventToPosition(evt);

      if (lastPos.value[0] === newPos[0] && lastPos.value[1] === newPos[1]) {
        return false;
      }

      lastPos.value = newPos;
      return true;
    },

    update(evt: PointerEvent) {
      lastPos.value = eventToPosition(evt);
    },
  };
}
