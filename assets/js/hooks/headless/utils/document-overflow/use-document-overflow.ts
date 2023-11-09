import { computed, type Ref } from "@vue/reactivity";
import { watch } from "@vue-reactivity/watch";

import { useStore } from "../use-store";
import { MetaFn, overflows } from "./overflow-store";

export function useDocumentOverflowLockedEffect(
  doc: Ref<Document | null>,
  shouldBeLocked: Ref<boolean>,
  meta: MetaFn
) {
  const { store, onUnmounted } = useStore(overflows);
  const locked = computed(() => {
    const entry = doc.value ? store.value.get(doc.value) : undefined;
    return entry ? entry.count > 0 : false;
  });

  watch(
    [doc, shouldBeLocked],
    ([doc, shouldBeLocked], [oldDoc], onInvalidate) => {
      if (!doc || !shouldBeLocked) {
        return;
      }

      // Prevent the document from scrolling
      overflows.dispatch("PUSH", doc, meta);

      // Allow document to scroll
      let didRunCleanup = false;
      onInvalidate(() => {
        if (didRunCleanup) return;
        overflows.dispatch("POP", oldDoc ?? doc, meta);

        // This shouldn't be necessary, but it is.
        // Seems like a Vue bug.
        didRunCleanup = true;
      });
    },
    {
      immediate: true,
    }
  );

  return { locked, onUnmounted };
}
