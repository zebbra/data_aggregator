import { type InjectionKey, provide } from "./inject-provide";
import { onInitialPageLoad } from "./utils";

export const AlertCommandContext = Symbol(
  "AlertCommandContext"
) as InjectionKey<string | null>;

// https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#link/1-overriding-the-default-confirm-behaviour
function onPhoenixLinkClickListener(e: Event) {
  // prevent propagation to default implementation
  e.stopPropagation();

  // we handle only html elements
  if (e.target instanceof HTMLElement === false) return;

  const target = e.target as HTMLElement;

  const message = target.dataset.confirm;
  if (!message) return;

  // either take the custom registered alert or the default alert from within
  // the layout
  const dialogId = target.dataset.confirm_id || "confirm_alert";
  const dialog = document.getElementById(dialogId) as HTMLDialogElement;

  // if none was defined, abort
  if (!dialog) return;

  // currently only supporting the phx-click event
  const phxEvent = target.getAttribute("phx-click");
  if (!phxEvent) return;

  // introduce alternative implementation if data-confirm is present
  // and store the command to be executed on confirm

  // prevent default implementation
  e.preventDefault();

  // set the command to be executed on confirm
  provide(dialogId, AlertCommandContext, phxEvent);

  dialog.showModal();
}

onInitialPageLoad(() => {
  // make sure listener is not registered twice
  document.body.removeEventListener(
    "phoenix.link.click",
    onPhoenixLinkClickListener
  );

  // override the default confirm behaviour
  // listen on document.body, so it's executed before the default of
  // phoenix_html, which is listening on the window object
  document.body.addEventListener(
    "phoenix.link.click",
    onPhoenixLinkClickListener,
    false
  );
});
