import { ref, Ref } from "@vue/reactivity";
import { consola } from "consola";

import { inject, provide, type InjectionKey } from "./utils/inject-provide";
import { useDescriptions } from "./description.hook";
import { nextFrame, rootId } from "./utils/helpers";
import { focusElement, getFocusableElements } from "./utils/focus-management";

enum DialogStates {
  Open,
  Closed,
}

type StateDefinition = {
  dialogState: Ref<DialogStates>;

  titleId: Ref<string | null>;
  panelRef: Ref<HTMLDivElement | null>;

  setTitleId(id: string | null): void;

  close(): void;
};

const DialogContext = Symbol("DialogContext") as InjectionKey<StateDefinition>;
function useDialogContext(instance: string, component: string) {
  let context = inject(instance, DialogContext);
  if (context === null) {
    let err = new Error(
      `<${component} /> is missing a parent <Dialog /> component.`
    );
    // @ts-expect-error
    if (Error.captureStackTrace) Error.captureStackTrace(err, useDialogContext);
    throw err;
  }
  return context;
}

const Dialog = {
  reset() {
    consola.debug("Dialog hook reset", this.el.id);
    provide(this.el.id, DialogContext, undefined as any);
  },
  destroyed() {
    consola.debug("Dialog hook destroyed", this.el.id);
    this.reset();
  },
  updated() {
    consola.debug("Dialog hook updated", this.el.id);
  },
  mounted() {
    this.reset();

    const role = this.el.getAttribute("role");
    if (["dialog", "alertdialog"].includes(role) === false) {
      consola.warn(
        `Invalid role [${role}] passed to <Dialog />. Only \`dialog\` and and \`alertdialog\` are supported. Using \`dialog\` instead.`
      );
      this.el.setAttribute("role", "dialog");
    }

    const dialogState = ref<DialogStates>(this.el.hasAttribute("aria-modal"));
    const panelRef = ref<HTMLDivElement | null>(null);
    const describedby = useDescriptions(rootId(this.el.id));
    const titleId = ref<StateDefinition["titleId"]["value"]>(null);
    const dialogId = this.el.id;

    const api: StateDefinition = {
      dialogState,
      titleId,
      panelRef,
      setTitleId(id: string | null) {
        if (titleId.value === id) return;
        titleId.value = id;
      },
      close(withDocumentClick = true) {
        if (dialogState.value === DialogStates.Closed) return;
        if (withDocumentClick) {
          document.body.click();
        } else {
          dialogState.value = DialogStates.Closed;

          const triggerButton = getFocusableElements().find(
            (el) => el.id === `${dialogId}__button`
          );
          if (triggerButton) nextFrame(() => focusElement(triggerButton));
        }
      },
    };

    provide(this.el.id, DialogContext, api);

    nextFrame(() => {
      if (titleId.value) {
        this.el.setAttribute("aria-labelledby", titleId.value!);
      }
      if (describedby.value) {
        this.el.setAttribute("aria-describedby", describedby.value!);
      }
    });

    consola.debug("Dialog hook mounted", this.el.id);
  },
};

const DialogPanel = {
  reset() {
    consola.debug("DialogPanel hook reset", this.el.id);
    this.el.removeEventListener("phx:hide-start", null);
  },
  destroyed() {
    consola.debug("DialogPanel hook destroyed", this.el.id);
    this.reset();
  },
  updated() {
    consola.debug("DialogPanel hook updated", this.el.id);
  },
  mounted() {
    this.reset();

    const api = useDialogContext(rootId(this.el.id), "DialogPanel");
    api.panelRef.value = this.el;

    this.el.addEventListener("phx:hide-start", () => {
      api.close(false);
    });

    consola.debug("DialogPanel hook mounted", this.el.id);
  },
};

const DialogTitle = {
  reset() {
    consola.debug("DialogTitle hook reset", this.el.id);
    const api = useDialogContext(rootId(this.el.id), "DialogTitle");
    api.setTitleId(null);
  },
  destroyed() {
    consola.debug("DialogTitle hook destroyed", this.el.id);
    this.reset();
  },
  updated() {
    consola.debug("DialogTitle hook updated", this.el.id);
  },
  mounted() {
    this.reset();

    const api = useDialogContext(rootId(this.el.id), "DialogTitle");
    api.setTitleId(this.el.id);

    consola.debug("DialogTitle hook mounted", this.el.id);
  },
};

export default Dialog;
export { DialogPanel, DialogTitle };
