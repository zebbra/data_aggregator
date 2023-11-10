import { ref, type Ref } from "@vue/reactivity";
import { dom } from "../utils/dom";
import { getOwnerDocument } from "../utils/owner";

export function useRootContainers({
  defaultContainers = [],
  portals,
  mainTreeNodeRef,
}: {
  defaultContainers?: (HTMLElement | null | Ref<HTMLElement | null>)[];
  portals?: Ref<HTMLElement[]>;
  mainTreeNodeRef?: Ref<HTMLElement | null>;
} = {}) {
  // Reference to a node in the "main" tree, not in the portalled Dialog tree.
  const ownerDocument = getOwnerDocument(mainTreeNodeRef);

  function resolveContainers() {
    const containers: HTMLElement[] = [];

    // Resolve default containers
    for (const container of defaultContainers) {
      if (container === null) continue;
      if (container instanceof HTMLElement) {
        containers.push(container);
      } else if (
        "value" in container &&
        container.value instanceof HTMLElement
      ) {
        containers.push(container.value);
      }
    }

    // Resolve portal containers
    if (portals?.value) {
      for (let portal of portals.value) {
        containers.push(portal);
      }
    }

    // Resolve third party (root) containers
    for (const container of ownerDocument?.querySelectorAll(
      "html > *, body > *"
    ) ?? []) {
      if (container === document.body) continue; // Skip `<body>`
      if (container === document.head) continue; // Skip `<head>`
      if (!(container instanceof HTMLElement)) continue; // Skip non-HTMLElements
      if (container.id === "headless-portal-root") continue; // Skip the Headless portal root
      if (container.contains(dom(mainTreeNodeRef))) continue; // Skip if it is the main app
      if (
        containers.some((defaultContainer) =>
          container.contains(defaultContainer)
        )
      ) {
        continue; // Skip if the current container is part of a container we've already seen (e.g.: default container / portal)
      }

      containers.push(container);
    }

    return containers;
  }

  return {
    resolveContainers,
    contains(element: HTMLElement) {
      return resolveContainers().some((container) =>
        container.contains(element)
      );
    },
  };
}
