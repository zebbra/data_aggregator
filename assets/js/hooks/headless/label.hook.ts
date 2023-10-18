import { computed, ref } from "@vue/reactivity";
import { consola } from "consola";
import { type InjectionKey, inject, provide } from "./utils/inject-provide";
import { nextFrame, rootId } from "./utils/helpers";

type StateDefinition = {
  register(value: string): () => void;
  props: Record<string, unknown>;
};

const LabelContext = Symbol("LabelContext") as InjectionKey<StateDefinition>;
function useLabelContext(instance: string) {
  const context = inject(instance, LabelContext);
  if (context === null) {
    const err = new Error(
      "You used a <Label /> component, but it is not inside a parent."
    );
    // @ts-expect-error
    if (Error.captureStackTrace) Error.captureStackTrace(err, useLabelContext);
    throw err;
  }

  return context;
}

export function useLabels(
  instance: string,
  props: Record<string, unknown> = {}
) {
  const labelIds = ref<string[]>([]);
  function register(value: string) {
    labelIds.value.push(value);
    return () => {
      const index = labelIds.value.indexOf(value);
      if (index !== -1) labelIds.value.splice(index, 1);
    };
  }

  provide(instance, LabelContext, { register, props });

  // The actual id's as string or undefined.
  return computed(() =>
    labelIds.value.length > 0 ? labelIds.value.join(" ") : undefined
  );
}

const Label = {
  reset() {
    consola.debug("Label hook reset", this.el.id);
    provide(this.el.id, LabelContext, undefined as any);
  },
  destroyed() {
    consola.debug("Label hook destroyed", this.el.id);
    this.reset();
  },
  mounted() {
    this.reset();

    const context = useLabelContext(rootId(this.el.id));
    context.register(this.el.id);

    if (this.el.hasAttribute("data-passive")) {
      this.el.removeAttribute("for");
      this.el.removeEventListener("click", (event: MouseEvent) => {
        context.props.onClick?.(event);
      });
    } else {
      nextFrame(() => {
        this.el.setAttribute("for", context.props.htmlFor.value);
        this.el.addEventListener("click", (event: MouseEvent) => {
          context.props.onClick?.(event);
        });
      });
    }

    consola.debug("Label hook mounted", this.el.id);
  },
};

export default Label;
