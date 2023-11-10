import { Ref } from "@vue/reactivity";

export function nextFrame(cb: () => void) {
  requestAnimationFrame(() => requestAnimationFrame(cb));
}

export function unwrap<T>(value: Ref<T> | T): T {
  // @ts-ignore
  return value?.value ?? value;
}

export function rootId(id: string) {
  return id.split("__").shift()!;
}

export function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export function debounce(func: Function, timeout = 300, leading = false) {
  let timer: ReturnType<typeof setTimeout> | undefined;

  return (...args: any[]) => {
    if (leading && !timer) {
      func.apply(this, args);
    }
    clearTimeout(timer);
    timer = setTimeout(() => {
      if (leading) {
        timer = undefined;
        return;
      }
      func.apply(this, args);
    }, timeout);
  };
}
