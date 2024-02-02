import { Hook, makeHook } from "./hook";

// https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#link/1-overriding-the-default-confirm-behaviour
class AlertHook extends Hook {
  execCmd(cmd: string | null | undefined): void {
    if (cmd && cmd !== "[]") {
      this.liveSocket.execJS(this.el, cmd);
    }
  }
  mounted(): void {
    const dialog = this.el as HTMLDialogElement;

    // if alert is controlled by :if={...} we need to show it
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
          dialog.returnValue = "cancel";
          dialog.close();
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
          dialog.returnValue = "confirm";
          dialog.close();
        }
      });
    }

    // store the command to be executed on confirm
    let cmd: string | null | undefined = null;

    dialog.addEventListener("close", (e) => {
      if (dialog.returnValue === "confirm") {
        // use the command stored on phx-click if present
        // otherwise use the command stored on data-confirm
        cmd = cmd || dialog.dataset["confirm"];
      } else {
        cmd = dialog.dataset["cancel"];
      }

      this.execCmd(cmd);
      // reset the command
      cmd = null;
    });

    // if we use the phx-submit attribute inside the modal form,
    // we need to close the dialog on submit and let the default
    // submit event do the rest
    dialog.addEventListener("submit:close", () => {
      dialog.returnValue = "confirm";
      dialog.close();
    });

    // override the default confirm behaviour
    // listen on document.body, so it's executed before the default of
    // phoenix_html, which is listening on the window object
    document.body.addEventListener(
      "phoenix.link.click",
      function (e) {
        // prevent propagation to default implementation
        e.stopPropagation();

        const target = e.target as HTMLElement;

        const message = target.getAttribute("data-confirm");
        if (!message) return;

        // currently only supporting the phx-click event
        const phxEvent = target.getAttribute("phx-click");
        if (!phxEvent) return;

        // introduce alternative implementation if data-confirm is present
        // and store the command to be executed on confirm

        // prevent default implementation
        e.preventDefault();

        // set the command to be executed on confirm
        cmd = phxEvent;

        dialog.showModal();
      },
      false
    );
  }
}

const alertHook = makeHook(AlertHook);

export default alertHook;
