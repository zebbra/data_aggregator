import { watchEffect } from "@vue-reactivity/watch";
import { type ComputedRef } from "@vue/reactivity";
import { getOwnerDocument } from "../utils/owner";

type AcceptNode = (
  node: HTMLElement
) =>
  | typeof NodeFilter.FILTER_ACCEPT
  | typeof NodeFilter.FILTER_SKIP
  | typeof NodeFilter.FILTER_REJECT;

export function useTreeWalker({
  container,
  accept,
  walk,
  enabled,
}: {
  container: ComputedRef<HTMLElement | null>;
  accept: AcceptNode;
  walk(node: HTMLElement): void;
  enabled?: ComputedRef<boolean>;
}) {
  watchEffect(() => {
    const root = container.value;
    if (!root) return;
    if (enabled !== undefined && !enabled.value) return;
    const ownerDocument = getOwnerDocument(container);
    if (!ownerDocument) return;

    const acceptNode = Object.assign((node: HTMLElement) => accept(node), {
      acceptNode: accept,
    });
    const walker = ownerDocument.createTreeWalker(
      root,
      NodeFilter.SHOW_ELEMENT,
      acceptNode,
      // @ts-expect-error This `false` is a simple small fix for older browsers
      false
    );

    while (walker.nextNode()) walk(walker.currentNode as HTMLElement);
  });
}
