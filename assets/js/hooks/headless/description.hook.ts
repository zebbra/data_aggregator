import { ref, computed } from "@vue/reactivity";
import { consola } from "consola";
import { inject, provide, type InjectionKey } from "./utils/inject-provide";
import { rootId } from "./utils/helpers";

type StateDefinition = {
  register(value: string): () => void;
  props: Record<string, unknown>;
};

const DescriptionContext = Symbol(
  "DescriptionContext"
) as InjectionKey<StateDefinition>;

function useDescriptionContext(instance: string) {
  const context = inject(instance, DescriptionContext);
  if (context === null) {
    const err = new Error(
      "You used a <Description /> component, but it is not inside a parent."
    );
    // @ts-expect-error
    if (Error.captureStackTrace) {
      // @ts-expect-error
      Error.captureStackTrace(err, useDescriptionContext);
    }
    throw err;
  }

  return context;
}

export function useDescriptions(
  instance: string,
  props: Record<string, unknown> = {}
) {
  const descriptionIds = ref<string[]>([]);
  function register(value: string) {
    descriptionIds.value.push(value);
    return () => {
      const index = descriptionIds.value.indexOf(value);
      if (index !== -1) descriptionIds.value.splice(index, 1);
    };
  }

  provide(instance, DescriptionContext, { register, props });

  // The actual id's as string or undefined.
  return computed(() =>
    descriptionIds.value.length > 0 ? descriptionIds.value.join(" ") : undefined
  );
}

const Description = {
  reset() {
    consola.debug("Description hook reset", this.el.id);
    provide(this.el.id, DescriptionContext, undefined as any);
  },
  destroyed() {
    consola.debug("Description hook destroyed", this.el.id);
    this.reset();
  },
  mounted() {
    this.reset();

    const context = useDescriptionContext(rootId(this.el.id));
    context.register(this.el.id);

    consola.debug("Description hook mounted", this.el.id);
  },
};

export default Description;
