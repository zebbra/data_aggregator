import { AlertCommandContext } from "../src/data-confirm-interceptor";
import { inject, provide } from "../src/inject-provide";
import { Hook, makeHook } from "./hook";

class DialogHook extends Hook {
  execCmd(cmd: string | null | undefined): void {
    if (cmd && cmd !== "[]") {
      this.liveSocket.execJS(this.el, cmd);
    }
  }

  mounted(): void {
    const dialog = this.el as HTMLDialogElement;

    // if dialog is controlled by :if={...} we need to show it
    // manually on mount if it's data-show attribute is present
    if (dialog.hasAttribute("data-show")) {
      dialog.showModal();
    }

    // fix the unwanted submit behaviour if the user presses enter or space
    // on the cancel button if the dialog was opened with a mouse click
    const cancelButton = dialog.querySelector("button[value='cancel']");
    if (cancelButton) {
      cancelButton.addEventListener("keydown", (e) => {
        if ([" ", "Enter"].includes((e as KeyboardEvent).key)) {
          e.preventDefault();
          dialog.close("cancel");
        }
      });
    }

    // fix the unwanted submit behaviour if the user presses enter or space
    // on the confirm button if the dialog was opened with a mouse click
    const confirmButton = dialog.querySelector("button[value='confirm']");
    if (confirmButton) {
      confirmButton.addEventListener("keydown", (e) => {
        if ([" ", "Enter"].includes((e as KeyboardEvent).key)) {
          e.preventDefault();
          dialog.close("confirm");
        }
      });
    }

    // if the on_cancel, on_confirm, or data-confirm attribute is present, we need to
    // execute the command on close
    dialog.addEventListener("close", () => {
      // if the return value is submit:close, we don't want to execute the command
      // as the form submit event will take care of it
      if (dialog.returnValue === "submit:close") return;

      let cmd: string | null | undefined = null;
      if (dialog.returnValue === "confirm") {
        // use the command stored on phx-click if present
        // otherwise use the command stored on data-confirm
        cmd =
          inject(dialog.id, AlertCommandContext) || dialog.dataset["confirm"];
      } else {
        cmd = dialog.dataset["cancel"];
      }

      this.execCmd(cmd);

      // reset the command
      provide(dialog.id, AlertCommandContext, null);
      cmd = undefined;
    });

    // if we use the phx-submit attribute inside the modal form,
    // we need to close the dialog on submit and let the default
    // submit event do the rest. in this case set the return value
    // to submit:close to prevent the on_cancel command from being executed
    dialog.addEventListener("submit:close", () => {
      dialog.close("submit:close");
    });

    this.handleEvent("submit:close", () => {
      dialog.close("submit:close");
    });
  }
  // if the dialog's show attribute is dynamically updated
  // we need to show it manually if it's data-show attribute is present
  // after the update
  updated(): void {
    const dialog = this.el as HTMLDialogElement;
    if (dialog.hasAttribute("data-show") && !dialog.open) {
      dialog.showModal();
    }
  }
}

const dialogHook = makeHook(DialogHook);

export default dialogHook;
