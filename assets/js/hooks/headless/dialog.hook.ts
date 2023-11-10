import { computed, type ComputedRef, ref, type Ref } from "@vue/reactivity";
import { watchEffect } from "@vue-reactivity/watch";
import { consola } from "consola";

import { inject, provide, type InjectionKey } from "./utils/inject-provide";
import { useDescriptions } from "./description.hook";
import { nextFrame, rootId } from "./utils/helpers";
import { focusElement, getFocusableElements } from "./utils/focus-management";
import { useResizeListener } from "./utils/use-resize-listener";
import { visible } from "./utils/use-breakpoint";
import { Keys } from "./utils/keyboard";
import { getOwnerDocument } from "./utils/owner";
import { useInert } from "./utils/use-inert";
import { useDocumentOverflowLockedEffect } from "./utils/document-overflow/use-document-overflow";
import { StackMessage, useStackProvider } from "./utils/stack-context";
import { match } from "./utils/match";
import { useRootContainers } from "./utils/use-root-containers";

enum DialogStates {
  Open,
  Closed,
  Closing,
}

type StateDefinition = {
  dialogState: Ref<DialogStates>;

  titleId: Ref<string | null>;
  describedby: ComputedRef<string | undefined>;
  panelRef: Ref<HTMLDivElement | null>;

  setTitleId(id: string | null): void;

  openDialog(): void;
  closeDialog(client?: boolean, cancel?: boolean): void;
};

const DialogContext = Symbol("DialogContext") as InjectionKey<StateDefinition>;
function useDialogContext(instance: string, component: string) {
  const context = inject(instance, DialogContext);
  if (context === null) {
    const err = new Error(
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

    if (this.onResizeHandler) {
      window.removeEventListener("resize", this.onResizeHandler);
    }

    provide(this.el.id, DialogContext, undefined as any);
  },
  destroyed() {
    consola.debug("Dialog hook destroyed", this.el.id);

    if (this.onEscapeListener) {
      getOwnerDocument(this.el)?.defaultView?.removeEventListener(
        "keydown",
        this.onEscapeListener
      );
    }
    this.reset();
  },
  updated() {
    consola.debug("Dialog hook updated", this.el.id);
    this.render();

    const api = useDialogContext(this.el.id, "Dialog");
    // this flag get's updated by the dialog.ex if the show attribute
    // is changed
    const propsOpen = this.el.getAttribute("phx-mounted");
    const enabled = api.dialogState.value === DialogStates.Open;

    // this approach works well for the :if directive as well
    // as in this case the phx-mounted attribute is not set
    // and the logic below is not applied
    if (propsOpen && !enabled) {
      // in case the dialog is responsive we need to check if the dialog
      // is visible
      const breakpoint = this.el.dataset["responsive"];
      if (breakpoint && !visible(breakpoint)) {
        return;
      }

      const cmd = this.el.getAttribute("phx-mounted");
      if (cmd) {
        api.openDialog(cmd);
      }
    } else if (!propsOpen && enabled) {
      // in case the close is triggered by the server we
      // have propsOpen=null and enabled=false

      // in case the dialog is responsive we need to check if the dialog
      // is still visible
      const breakpoint = this.el.dataset["responsive"];
      const staticMode = this.el.hasAttribute("data-static");
      if (breakpoint && visible(breakpoint) && !staticMode) {
        return;
      }

      const cmd = this.el.dataset["cancel"];
      if (cmd) {
        api.closeDialog();
      }
    }
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

    // Handle `Open` state
    // have a look at dialog.ex. if the phx-mounted attribute is set, the dialog is shown
    // on initial render. thus this attribute acts as a flag
    const propsOpen = this.el.getAttribute("phx-mounted");
    const dialogState = ref<DialogStates>(
      propsOpen ? DialogStates.Open : DialogStates.Closed
    );
    const enabled = computed(() => dialogState.value === DialogStates.Open);

    const internalDialogRef = ref(this.el);
    const ownerDocument = computed(() => getOwnerDocument(internalDialogRef));
    const panelRef = ref<HTMLDivElement | null>(null);

    const parentId = this.el.dataset.parentid;
    const hasParentDialog = inject(parentId, DialogContext, null) !== null;
    const nestedDialogCount = ref(0);
    const hasNestedDialogs = computed(() => nestedDialogCount.value > 1); // 1 because the current dialog is also counted

    // Handle `inert` effect
    // Ensure other elements can't be interacted with
    const inertOthersEnabled = computed(() => {
      // Nested dialogs should not modify the `inert` property, only the root one should.
      if (hasParentDialog) return false;
      return enabled.value;
    });
    const resolveRootOfMainTreeNode = computed(() => {
      return (Array.from(
        ownerDocument.value?.querySelectorAll("body > [data-phx-main] > *") ??
          []
      ).find((root) => {
        // Skip the portal root, we don't want to make that one inert
        if (root.id === "headless-portal-root") return false;
        // Skip the flash group, we don't want to make that one inert
        if (root.id === "flash-group") return false;

        // Have a look at your template. We assume a structure like this:
        // <body>
        //   <div data-phx-main>
        //    <div>...</div> -> rootOfMainTreeNode
        //    <div id="headless-portal-root">...</div> -> dialog container
        //    <div id="flash-group">...</div> -> flash messages
        //   </div>
        // </body>
        return true;
      }) ?? null) as HTMLElement | null;
    });
    useInert(resolveRootOfMainTreeNode, inertOthersEnabled);

    const portals = ref<HTMLElement[]>([]);
    const { resolveContainers: resolveRootContainers } = useRootContainers({
      portals,
      defaultContainers: [
        computed(() => api.panelRef.value ?? internalDialogRef.value),
      ],
    });

    // Handle `Scroll lock` effect
    const scrollLockEnabled = computed(() => {
      if (enabled.value === false) return false;
      if (hasParentDialog) return false;
      return true;
    });
    const { onUnmounted: onUnmountDocumentOverflowLockedEffect } =
      useDocumentOverflowLockedEffect(
        ref(ownerDocument),
        scrollLockEnabled,
        (meta) => ({
          containers: [...(meta.containers ?? []), resolveRootContainers],
        })
      );

    // if parentId use some kind of a stack provider to let the parent know that the dialog has been opened
    // in case that this is the parent of an open dialog, prevent esc from closing this dialog
    // also kind of make sure that scrolling in the child dialog prevents scrolling in the parent dialog

    // Handle `Nested` dialogs
    const onUnmountedStackProvider = useStackProvider({
      instance: this.el.id,
      parentInstance: this.el.dataset.parentid ?? "",
      type: "dialog",
      enabled,
      element: internalDialogRef,
      onUpdate: (message, type) => {
        if (type !== "dialog") return;

        return match(message, {
          [StackMessage.Add]: () => (nestedDialogCount.value += 1),
          [StackMessage.Remove]: () => (nestedDialogCount.value -= 1),
        });
      },
    });

    const describedby = useDescriptions(rootId(this.el.id));
    const titleId = ref<StateDefinition["titleId"]["value"]>(null);
    const dialogId = this.el.id;

    const api: StateDefinition = {
      dialogState,
      titleId,
      describedby,
      panelRef,
      setTitleId(id: string | null) {
        if (titleId.value === id) return;
        titleId.value = id;
      },
      openDialog: () => {
        // in case we use the responsive feature the phx-mounted is not available
        // so we use the data-show attribute instead
        const cmd =
          this.el.getAttribute("phx-mounted") || this.el.dataset["show"];

        this.liveSocket.execJS(this.el, cmd);
        dialogState.value = DialogStates.Open;
      },
      closeDialog: (client = true, cancel = false) => {
        if (dialogState.value === DialogStates.Closed) {
          return;
        }

        if (client) {
          this.liveSocket.execJS(
            this.el,
            this.el.dataset[cancel ? "cancel" : "hide"]
          );
        } else {
          dialogState.value = DialogStates.Closed;
          onUnmountedStackProvider(); // notify the parent (and self) that the dialog has been closed
          onUnmountDocumentOverflowLockedEffect(); // unlock the document
          const triggerButton = getFocusableElements().find(
            (el) => el.id === `${dialogId}__button`
          );
          if (triggerButton) nextFrame(() => focusElement(triggerButton));
        }
      },
    };

    provide(this.el.id, DialogContext, api);

    // Handle `Responsive` dialog
    // If the dialog is responsive we need to listen to the resize event
    // and open the dialog if the breakpoint is reached and
    // we also need to close the dialog if the breakpoint is not
    // reached anymore
    const breakpoint = this.el.dataset["responsive"];
    if (breakpoint) {
      this.onResizeHandler = useResizeListener.bind(this)(
        api.closeDialog,
        api.openDialog,
        breakpoint
      );
      window.addEventListener("resize", this.onResizeHandler);
    }

    // In case of a responsive dialog we need to check if the dialog should be shown
    // on mount for the current client window breakpoint
    const closed = api.dialogState.value === DialogStates.Closed;
    // Static mode is used when when the dialog is responsive and
    // show attribute is dynamic (not used with :if directive)
    const staticMode = this.el.hasAttribute("data-static");

    if (breakpoint && visible(breakpoint) && closed && !staticMode) {
      api.openDialog();
    }

    // Handle `Escape` to close
    const escapeToCloseEnabled = computed(() => {
      if (hasNestedDialogs.value) return false;
      if (dialogState.value !== DialogStates.Open) return false;
      return true;
    });

    this.onEscapeListener = (event: KeyboardEvent) => {
      if (!escapeToCloseEnabled.value) return;
      if (event.defaultPrevented) return;
      if (event.key !== Keys.Escape) return;

      event.preventDefault();
      event.stopPropagation();
      api.closeDialog(true, true);
    };

    ownerDocument.value?.defaultView?.addEventListener(
      "keydown",
      this.onEscapeListener
    );

    // Trigger close when the FocusTrap gets hidden
    watchEffect((onInvalidate) => {
      if (dialogState.value !== DialogStates.Open) return;

      const observer = new ResizeObserver((entries) => {
        for (const entry of entries) {
          const rect = entry.target.getBoundingClientRect();
          if (
            rect.x === 0 &&
            rect.y === 0 &&
            rect.width === 0 &&
            rect.height === 0
          ) {
            api.closeDialog(true, true);
          }
        }
      });

      observer.observe(this.el);

      onInvalidate(() => {
        if (dialogState.value === DialogStates.Closing) return;
        observer.disconnect();
      });
    });

    nextFrame(() => {
      this.render();
    });

    consola.debug("Dialog hook mounted", this.el.id);
  },
  render() {
    const api = useDialogContext(rootId(this.el.id), "Dialog");
    if (api.titleId.value) {
      this.el.setAttribute("aria-labelledby", api.titleId.value!);
    }
    if (api.describedby.value) {
      this.el.setAttribute("aria-describedby", api.describedby.value!);
    }
  },
};

const DialogPanel = {
  reset() {
    consola.debug("DialogPanel hook reset", this.el.id);
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
      api.dialogState.value = DialogStates.Closing;
      api.closeDialog(false);
    });

    consola.debug("DialogPanel hook mounted", this.el.id);
  },
};

const DialogTitle = {
  reset() {
    consola.debug("DialogTitle hook reset", this.el.id);
    const api = useDialogContext(rootId(this.el.id), "DialogTitle");
    api?.setTitleId(null);
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
