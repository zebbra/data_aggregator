import { type Ref } from "@vue/reactivity";
import { watch } from "@vue-reactivity/watch";
import { inject, provide, type InjectionKey } from "./inject-provide";

type OnUpdate = (
  message: StackMessage,
  type: string,
  element: Ref<HTMLElement | null>
) => void;

const StackContext = Symbol("StackContext") as InjectionKey<OnUpdate>;

export enum StackMessage {
  Add,
  Remove,
}

export function useStackContext(instance: string) {
  return inject(instance, StackContext, () => {});
}

export function useStackProvider({
  instance,
  parentInstance,
  type,
  enabled,
  element,
  onUpdate,
}: {
  instance: string;
  parentInstance: string;
  type: string;
  enabled: Ref<boolean | undefined>;
  element: Ref<HTMLElement | null>;
  onUpdate?: OnUpdate;
}) {
  const parentUpdate = useStackContext(parentInstance);

  function notify(...args: Parameters<OnUpdate>) {
    // Notify our layer
    onUpdate?.(...args);

    // Notify the parent
    parentUpdate(...args);
  }

  function onUnmounted() {
    if (enabled.value) {
      notify(StackMessage.Remove, type, element);
    }
  }

  watch(
    enabled,
    (isEnabled, oldIsEnabled) => {
      if (isEnabled) {
        notify(StackMessage.Add, type, element);
      } else if (oldIsEnabled === true) {
        notify(StackMessage.Remove, type, element);
      }
    },
    { immediate: true, flush: "sync" }
  );

  provide(instance, StackContext, notify);

  return onUnmounted;
}
