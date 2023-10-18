import { Ref, computed, ref } from "@vue/reactivity";
import { consola } from "consola";

import { provide, type InjectionKey, inject } from "./utils/inject-provide";
import { useLabels } from "./label.hook";
import { useDescriptions } from "./description.hook";
import { Keys } from "./utils/keyboard";
import { nextFrame, rootId } from "./utils/helpers";
import { useControllable } from "./utils/use-controllable";
import { attemptSubmit } from "./utils/form";

type StateDefinition = {
  // State
  switchRef: Ref<HTMLButtonElement | null>;
  labelledby: Ref<string | undefined>;
  describedby: Ref<string | undefined>;
};

const SwitchGroupContext = Symbol(
  "SwitchGroupContext"
) as InjectionKey<StateDefinition>;

const SwitchGroup = {
  reset() {
    consola.debug("SwitchGroup hook reset", this.el.id);
    provide(this.el.id, SwitchGroupContext, undefined as any);
  },
  destroyed() {
    consola.debug("SwitchGroup hook destroyed", this.el.id);
    this.reset();
  },
  mounted() {
    this.reset();

    const switchRef = ref<StateDefinition["switchRef"]["value"]>(null);
    const labelledby = useLabels(rootId(this.el.id), {
      htmlFor: computed(() => switchRef.value?.id),
      onClick(event: MouseEvent & { currentTarget: HTMLElement }) {
        if (!switchRef.value) return;
        if (event.currentTarget.tagName === "LABEL") {
          event.preventDefault();
        }
        switchRef.value.click();
        switchRef.value.focus({ preventScroll: true });
      },
    });
    const describedby = useDescriptions(rootId(this.el.id));

    const api = {
      switchRef,
      labelledby,
      describedby,
    };

    provide(this.el.id, SwitchGroupContext, api);
    consola.debug("SwitchGroup hook mounted", this.el.id);
  },
};

const Switch = {
  reset() {
    consola.debug("Switch hook reset", this.el.id);
  },
  destroyed() {
    consola.debug("Switch hook destroyed", this.el.id);
    this.reset();
  },
  updated() {
    consola.debug("Switch hook updated", this.el.id);
    this.render();
  },
  mounted() {
    this.reset();

    const api = inject(`${rootId(this.el.id)}__group`, SwitchGroupContext);
    if (api) api.switchRef.value = this.el;

    const internalSwitchRef = ref<StateDefinition["switchRef"]["value"]>(
      this.el
    );
    const switchRef = api ? api.switchRef : internalSwitchRef;

    const hiddenInputRef =
      this.el.previousElementSibling?.tagName === "INPUT"
        ? ref(this.el.previousElementSibling as HTMLInputElement)
        : ref(undefined);
    const value = hiddenInputRef.value?.getAttribute("value") || "";

    const modelValue = ref(this.el.hasAttribute("aria-checked"));
    this.dataRef = computed(() => ({
      modelValue,
      value,
      switchRef,
      hiddenInputRef,
    }));

    this.render();

    const [checked, onChange] = useControllable(
      computed(() => modelValue.value),
      (value) => {
        modelValue.value = value;
        this.render();
      }
    );

    function toggle() {
      onChange(!checked.value);
    }

    function handleClick(event: MouseEvent) {
      event.preventDefault();
      toggle();
    }

    function handleKeyUp(event: KeyboardEvent) {
      if (event.key === Keys.Space) {
        event.preventDefault();
        toggle();
      } else if (event.key === Keys.Enter) {
        attemptSubmit(event.currentTarget as HTMLElement);
      }
    }

    // This is needed so that we can "cancel" the click event when we use the `Enter` key on a button.
    function handleKeyPress(event: KeyboardEvent) {
      event.preventDefault();
    }

    switchRef.value.addEventListener("click", handleClick);
    switchRef.value.addEventListener("keyup", handleKeyUp);
    switchRef.value.addEventListener("keypress", handleKeyPress);

    if (api) {
      nextFrame(() => {
        if (api.labelledby.value) {
          switchRef.value.setAttribute("aria-labelledby", api.labelledby.value);
        }
        if (api.describedby.value) {
          switchRef.value.setAttribute(
            "aria-describedby",
            api.describedby.value
          );
        }
      });
    }

    consola.debug("Switch hook mounted", this.el.id);
  },
  render() {
    if (this.dataRef.value.modelValue.value) {
      this.dataRef.value.switchRef.value.setAttribute("aria-checked", "true");
      this.dataRef.value.switchRef.value.classList.add(
        "group/checked",
        "is-checked"
      );
      this.dataRef.value.hiddenInputRef.value?.setAttribute("checked", "");
      this.dataRef.value.hiddenInputRef.value?.setAttribute(
        "value",
        this.dataRef.value.value
      );
    } else {
      this.dataRef.value.switchRef.value.setAttribute("aria-checked", "false");
      this.dataRef.value.switchRef.value.classList.remove(
        "group/checked",
        "is-checked"
      );
      this.dataRef.value.hiddenInputRef.value?.removeAttribute("checked");
      this.dataRef.value.hiddenInputRef.value?.removeAttribute("value");
    }
  },
};

export default Switch;
export { SwitchGroup };
