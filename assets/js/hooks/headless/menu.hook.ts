import {
  Ref,
  ref,
  ComputedRef,
  computed,
  UnwrapNestedRefs,
} from "@vue/reactivity";
import { consola } from "consola";

import { Focus, calculateActiveIndex } from "./utils/calculate-active-index";
import {
  Focus as FocusManagementFocus,
  focusFrom,
  restoreFocusIfNecessary,
  sortByDomNode,
} from "./utils/focus-management";
import { dom } from "./utils/dom";
import { inject, provide, type InjectionKey } from "./utils/inject-provide";
import { Keys } from "./utils/keyboard";
import { nextFrame, rootId, unwrap } from "./utils/helpers";
import { useTextValue } from "./utils/get-text-value";
import { useTrackedPointer } from "./utils/use-tracked-pointer";

enum MenuStates {
  Open,
  Closed,
}

enum ActivationTrigger {
  Pointer,
  Other,
}

type MenuItemData = {
  textValue: string;
  disabled: boolean;
  domRef: Ref<HTMLElement | null>;
};

type StateDefinition = {
  // State
  menuState: Ref<MenuStates>;
  buttonRef: Ref<HTMLButtonElement | null>;
  itemsRef: Ref<HTMLDivElement | null>;
  items: Ref<{ id: string; dataRef: ComputedRef<MenuItemData> }[]>;
  searchQuery: Ref<string>;
  activeItemIndex: Ref<number | null>;
  activationTrigger: Ref<ActivationTrigger>;

  // State mutators
  closeMenu(withDocumentClick?: boolean): void;
  openMenu(buttonRef?: Ref<HTMLButtonElement | null>): void;
  goToItem(focus: Focus, id?: string, trigger?: ActivationTrigger): void;
  search(value: string): void;
  clearSearch(): void;
  registerItem(id: string, dataRef: ComputedRef<MenuItemData>): void;
  unregisterItem(id: string): void;
};

const MenuContext = Symbol("MenuContext") as InjectionKey<StateDefinition>;
function useMenuContext(instance: string, component: string) {
  const context: StateDefinition = inject(instance, MenuContext);

  if (context === null) {
    const err = new Error(
      `<${component} /> is missing a parent <Menu /> component.`
    );
    // @ts-expect-error
    if (Error.captureStackTrace) {
      // @ts-expect-error
      Error.captureStackTrace(err, useMenuContext);
    }
    throw err;
  }

  return context;
}

const Menu = {
  reset() {
    consola.debug("Menu hook reset", this.el.id);
    provide(this.el.id, MenuContext, undefined as any);
  },
  destroyed() {
    consola.debug("Menu hook destroyed", this.el.id);
    this.reset();
  },
  mounted() {
    this.reset();

    const menuState = ref<StateDefinition["menuState"]["value"]>(
      MenuStates.Closed
    );
    const buttonRef = ref<StateDefinition["buttonRef"]["value"]>(null);
    const itemsRef = ref<StateDefinition["itemsRef"]["value"]>(null);
    const items = ref<StateDefinition["items"]["value"]>([]);
    const searchQuery = ref<StateDefinition["searchQuery"]["value"]>("");
    const activeItemIndex =
      ref<StateDefinition["activeItemIndex"]["value"]>(null);
    const activationTrigger = ref<
      StateDefinition["activationTrigger"]["value"]
    >(ActivationTrigger.Other);

    function adjustOrderedState(
      adjustment: (
        items: UnwrapNestedRefs<StateDefinition["items"]["value"]>
      ) => UnwrapNestedRefs<StateDefinition["items"]["value"]> = (i) => i
    ) {
      const currentActiveItem =
        activeItemIndex.value !== null
          ? items.value[activeItemIndex.value]
          : null;

      const sortedItems = sortByDomNode(
        adjustment(items.value.slice()),
        (item) => dom(item.dataRef.domRef)
      );

      // If we inserted an item before the current active item then the active item index
      // would be wrong. To fix this, we will re-lookup the correct index.
      let adjustedActiveItemIndex = currentActiveItem
        ? sortedItems.indexOf(currentActiveItem)
        : null;

      // Reset to `null` in case the currentActiveItem was removed.
      if (adjustedActiveItemIndex === -1) {
        adjustedActiveItemIndex = null;
      }

      return {
        items: sortedItems,
        activeItemIndex: adjustedActiveItemIndex,
      };
    }

    function handleActiveStateChange(
      items: { id: string; dataRef: MenuItemData }[],
      activeItemIndex: Ref<number | null>,
      nextActiveItemIndex: number | null
    ) {
      if (activeItemIndex.value === nextActiveItemIndex) return;
      if (activeItemIndex.value !== null) {
        const currentItem = items[activeItemIndex.value];
        currentItem.dataRef.domRef.value?.removeAttribute("aria-selected");
      }
      if (nextActiveItemIndex === null) return;
      const nextItem = items[nextActiveItemIndex];
      nextItem.dataRef.domRef.value?.setAttribute("aria-selected", "true");
    }

    const api = {
      menuState,
      buttonRef,
      itemsRef,
      items,
      searchQuery,
      activeItemIndex,
      activationTrigger,
      closeMenu: (withDocumentClick = true) => {
        if (menuState.value === MenuStates.Closed) return;
        if (withDocumentClick) {
          document.body.click();
        } else {
          handleActiveStateChange(items.value, activeItemIndex, null);
          menuState.value = MenuStates.Closed;
          activeItemIndex.value = null;
          searchQuery.value = "";
        }
      },
      openMenu: (buttonRef?: Ref<HTMLButtonElement | null>) => {
        if (menuState.value === MenuStates.Closed && buttonRef) {
          buttonRef.value?.click();
        }
        menuState.value = MenuStates.Open;
      },
      goToItem(focus: Focus, id?: string, trigger?: ActivationTrigger) {
        const adjustedState = adjustOrderedState();
        const nextActiveItemIndex = calculateActiveIndex(
          focus === Focus.Specific
            ? { focus: Focus.Specific, id: id! }
            : { focus: focus as Exclude<Focus, Focus.Specific> },
          {
            resolveItems: () => adjustedState.items,
            resolveActiveIndex: () => adjustedState.activeItemIndex,
            resolveId: (item) => item.id,
            resolveDisabled: (item) => item.dataRef.disabled,
          }
        );

        handleActiveStateChange(
          adjustedState.items,
          activeItemIndex,
          nextActiveItemIndex
        );

        searchQuery.value = "";
        activeItemIndex.value = nextActiveItemIndex;
        activationTrigger.value = trigger ?? ActivationTrigger.Other;
        items.value = adjustedState.items;
      },
      search(value: string) {
        const wasAlreadySearching = searchQuery.value !== "";
        const offset = wasAlreadySearching ? 0 : 1;
        searchQuery.value += value.toLowerCase();

        const reOrderedItems =
          activeItemIndex.value !== null
            ? items.value
                .slice(activeItemIndex.value + offset)
                .concat(items.value.slice(0, activeItemIndex.value + offset))
            : items.value;

        const matchingItem = reOrderedItems.find(
          (item) =>
            item.dataRef.textValue.startsWith(searchQuery.value) &&
            !item.dataRef.disabled
        );

        const matchIdx = matchingItem ? items.value.indexOf(matchingItem) : -1;
        if (matchIdx === -1 || matchIdx === activeItemIndex.value) return;

        handleActiveStateChange(items.value, activeItemIndex, matchIdx);

        activeItemIndex.value = matchIdx;
        activationTrigger.value = ActivationTrigger.Other;
      },
      clearSearch() {
        searchQuery.value = "";
      },
      registerItem(id: string, dataRef: MenuItemData) {
        const adjustedState = adjustOrderedState((items) => {
          return [...items, { id, dataRef }];
        });

        // handleActiveStateChange(
        //   adjustedState.items,
        //   activeItemIndex,
        //   adjustedState.activeItemIndex
        // );

        items.value = adjustedState.items;
        activeItemIndex.value = adjustedState.activeItemIndex;
        activationTrigger.value = ActivationTrigger.Other;
      },
      unregisterItem(id: string) {
        const adjustedState = adjustOrderedState((items) => {
          const idx = items.findIndex((a) => a.id === id);
          if (idx !== -1) items.splice(idx, 1);
          return items;
        });

        // handleActiveStateChange(
        //   adjustedState.items,
        //   activeItemIndex,
        //   adjustedState.activeItemIndex
        // );

        items.value = adjustedState.items;
        activeItemIndex.value = adjustedState.activeItemIndex;
        activationTrigger.value = ActivationTrigger.Other;
      },
    };

    // @ts-expect-error
    provide(this.el.id, MenuContext, api);
    consola.debug("Menu hook mounted", this.el.id);
  },
};

const MenuButton = {
  reset() {
    consola.debug("MenuButton hook reset", this.el.id);
    this.el.removeEventListener("keydown", this.handleKeyDown);
    this.el.removeEventListener("keyup", this.handleKeyUp);
    this.el.removeEventListener("click", this.handleClick);
  },
  destroyed() {
    consola.debug("MenuButton hook destroyed", this.el.id);
    this.reset();
  },
  mounted() {
    this.reset();
    const api = useMenuContext(rootId(this.el.id), "MenuButton");
    api.buttonRef.value = this.el;
    const disabled = this.el.getAttribute("disabled") !== null;

    function handleKeyDown(event: KeyboardEvent) {
      switch (event.key) {
        // Ref: https://www.w3.org/WAI/ARIA/apg/patterns/menubutton/#keyboard-interaction-13

        case Keys.Space:
        case Keys.Enter:
        case Keys.ArrowDown:
          event.preventDefault();
          event.stopPropagation();
          api.openMenu(api.buttonRef);
          nextFrame(() => {
            dom(api.itemsRef)?.focus({ preventScroll: true });
            api.goToItem(Focus.First);
          });
          break;

        case Keys.ArrowUp:
          event.preventDefault();
          event.stopPropagation();
          api.openMenu(api.buttonRef);
          nextFrame(() => {
            dom(api.itemsRef)?.focus({ preventScroll: true });
            api.goToItem(Focus.Last);
          });
          break;
      }
    }

    function handleKeyUp(event: KeyboardEvent) {
      switch (event.key) {
        case Keys.Space:
          // Required for firefox, event.preventDefault() in handleKeyDown for
          // the Space key doesn't cancel the handleKeyUp, which in turn
          // triggers a *click*.
          event.preventDefault();
          break;
      }
    }

    function handleClick(event: MouseEvent) {
      if (disabled) return;
      if (api.menuState.value === MenuStates.Open) {
        api.closeMenu();
        nextFrame(() => dom(api.buttonRef)?.focus({ preventScroll: true }));
      } else {
        event.preventDefault();
        api.openMenu();
        nextFrame(() => {
          dom(api.itemsRef)?.focus({ preventScroll: true });
        });
      }
    }

    this.el.addEventListener("keydown", handleKeyDown);
    this.el.addEventListener("keyup", handleKeyUp);
    this.el.addEventListener("click", handleClick);
    consola.debug("MenuButton hook mounted", this.el.id);
  },
};

const MenuItems = {
  reset() {
    consola.debug("MenuItems hook reset", this.el.id);
    this.el.removeEventListener("keydown", this.handleKeyDown);
    this.el.removeEventListener("keyup", this.handleKeyUp);
    this.el.removeEventListener("phx:hide-start", this.handleClick);
  },
  destroyed() {
    consola.debug("MenuItems hook destroyed", this.el.id);
    this.reset();
  },
  mounted() {
    this.reset();
    const api = useMenuContext(rootId(this.el.id), "MenuItems");
    api.itemsRef.value = this.el;

    const searchDebounce = ref<ReturnType<typeof setTimeout> | null>(null);

    function handleKeyDown(event: KeyboardEvent) {
      if (searchDebounce.value) clearTimeout(searchDebounce.value);

      switch (event.key) {
        // Ref: https://www.w3.org/WAI/ARIA/apg/patterns/menu/#keyboard-interaction-12

        // // @ts-expect-error Fallthrough is expected here
        case Keys.Space:
          if (api.searchQuery.value !== "") {
            event.preventDefault();
            event.stopPropagation();
            return api.search(event.key);
          }
        // When in type ahead mode, fallthrough
        case Keys.Enter:
          event.preventDefault();
          event.stopPropagation();
          if (api.activeItemIndex.value !== null) {
            const activeItem = api.items.value[api.activeItemIndex.value];
            const _activeItem = activeItem as unknown as UnwrapNestedRefs<
              typeof activeItem
            >;
            dom(_activeItem.dataRef.domRef)?.click();
          }
          api.closeMenu();
          restoreFocusIfNecessary(dom(api.buttonRef));
          break;

        case Keys.ArrowDown:
          event.preventDefault();
          event.stopPropagation();
          return api.goToItem(Focus.Next);

        case Keys.ArrowUp:
          event.preventDefault();
          event.stopPropagation();
          return api.goToItem(Focus.Previous);

        case Keys.Home:
        case Keys.PageUp:
          event.preventDefault();
          event.stopPropagation();
          return api.goToItem(Focus.First);

        case Keys.End:
        case Keys.PageDown:
          event.preventDefault();
          event.stopPropagation();
          return api.goToItem(Focus.Last);

        case Keys.Escape:
          event.preventDefault();
          event.stopPropagation();
          api.closeMenu();
          nextFrame(() => dom(api.buttonRef)?.focus({ preventScroll: true }));
          break;

        case Keys.Tab:
          event.preventDefault();
          event.stopPropagation();
          api.closeMenu();
          nextFrame(() =>
            focusFrom(
              dom(api.buttonRef),
              event.shiftKey
                ? FocusManagementFocus.Previous
                : FocusManagementFocus.Next
            )
          );
          break;

        default:
          if (event.key.length === 1) {
            api.search(event.key);
            searchDebounce.value = setTimeout(() => api.clearSearch(), 350);
          }
          break;
      }
    }

    function handleKeyUp(event: KeyboardEvent) {
      switch (event.key) {
        case Keys.Space:
          // Required for firefox, event.preventDefault() in handleKeyDown for
          // the Space key doesn't cancel the handleKeyUp, which in turn
          // triggers a *click*.
          event.preventDefault();
          break;
      }
    }

    this.el.addEventListener("keydown", handleKeyDown);
    this.el.addEventListener("keyup", handleKeyUp);
    this.el.addEventListener("phx:hide-start", () => {
      api.closeMenu(false);
    });
    consola.debug("MenuItems hook mounted", this.el.id);
  },
};

const MenuItem = {
  reset() {
    consola.debug("MenuItem hook reset", this.el.id);
    const api = useMenuContext(rootId(this.el.id), "MenuItem");
    api?.unregisterItem(this.el.id);
    this.el.removeEventListener("click", this.handleClick);
    this.el.removeEventListener("focus", this.handleFocus);
    this.el.removeEventListener("pointerenter", this.handleEnter);
    this.el.removeEventListener("mouseenter", this.handleEnter);
    this.el.removeEventListener("pointermove", this.handleMove);
    this.el.removeEventListener("mousemove", this.handleMove);
    this.el.removeEventListener("pointerleave", this.handleLeave);
    this.el.removeEventListener("mouseleave", this.handleLeave);
  },
  destroyed() {
    consola.debug("MenuItem hook destroyed", this.el.id);
    this.reset();
  },
  beforeUpdate() {
    consola.debug("MenuItem hook before update", this.el.id);
  },
  updated() {
    consola.debug("MenuItem hook updated", this.el.id);
    this.render();
  },
  mounted() {
    this.reset();
    const api = useMenuContext(rootId(this.el.id), "MenuItem");
    const internalItemRef = ref<HTMLElement>(this.el);
    const disabled = internalItemRef.value.getAttribute("disabled") !== null;

    const active = computed(() => {
      return api.activeItemIndex.value !== null
        ? api.items.value[api.activeItemIndex.value].id ===
            internalItemRef.value.id
        : false;
    });

    const getTextValue = useTextValue(ref(this.el));
    const dataRef = computed<MenuItemData>(() => ({
      disabled,
      get textValue() {
        return getTextValue();
      },
      domRef: internalItemRef,
    }));

    api.registerItem(this.el.id, dataRef);
    this.dataRef = dataRef;

    function handleClick(event: MouseEvent) {
      if (disabled) return event.preventDefault();
      api.closeMenu();
      restoreFocusIfNecessary(dom(api.buttonRef));
    }

    function handleFocus() {
      if (disabled) return api.goToItem(Focus.Nothing);
      api.goToItem(Focus.Specific, internalItemRef.value.id);
    }

    const pointer = useTrackedPointer();

    function handleEnter(evt: PointerEvent) {
      pointer.update(evt);
    }

    function handleMove(evt: PointerEvent) {
      if (!pointer.wasMoved(evt)) return;
      if (disabled) return;
      if (active.value) return;
      api.goToItem(
        Focus.Specific,
        internalItemRef.value.id,
        ActivationTrigger.Pointer
      );
    }

    function handleLeave(evt: PointerEvent) {
      if (!pointer.wasMoved(evt)) return;
      if (disabled) return;
      if (!active.value) return;
      api.goToItem(Focus.Nothing);
    }

    this.el.addEventListener("click", handleClick);
    this.el.addEventListener("focus", handleFocus);
    this.el.addEventListener("pointerenter", handleEnter);
    this.el.addEventListener("mouseenter", handleEnter);
    this.el.addEventListener("pointermove", handleMove);
    this.el.addEventListener("mousemove", handleMove);
    this.el.addEventListener("pointerleave", handleLeave);
    this.el.addEventListener("mouseleave", handleLeave);

    this.render();
    consola.debug("MenuItem hook mounted", this.el.id);
  },
  render() {
    if (this.dataRef.value.disabled) {
      this.el.setAttribute("aria-disabled", "true");
      this.el.classList.add("opacity-50", "pointer-events-none");
    } else {
      this.el.setAttribute("tabindex", "-1");
    }
  },
};

export default Menu;
export { MenuButton, MenuItems, MenuItem };
