import { Hook, makeHook } from "./hook";

class ModalHook extends Hook {
  mounted(): void {
    const dialog = this.el as HTMLDialogElement;

    // if modal is controlled by :if={...} we need to show it
    // manually on mount if it's data-show attribute is present
    if (dialog.hasAttribute("data-show")) {
      dialog.showModal();
    }

    // if the on_cancel attribute is present, we need to
    // execute the command on close
    dialog.addEventListener("close", () => {
      const cmd = dialog.dataset["cancel"];
      if (cmd && cmd !== "[]") {
        this.liveSocket.execJS(dialog, cmd);
      }
    });

    // if we use the phx-submit attribute inside the modal form,
    // we need to close the dialog on submit and let the default
    // submit event do the rest
    dialog.addEventListener("submit:close", () => {
      dialog.close();
    });
  }
}

const modalHook = makeHook(ModalHook);

export default modalHook;
