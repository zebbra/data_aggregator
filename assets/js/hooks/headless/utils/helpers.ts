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
