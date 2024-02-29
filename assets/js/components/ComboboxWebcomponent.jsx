import * as ReactDOM from "react-dom/client";
import Combobox from "./Combobox";

// https://github.com/ftes/phoenix-headlessui
// https://reactjs.org/docs/web-components.html#using-react-in-your-web-components
export default class ComboboxWebcomponent extends HTMLElement {
  connectedCallback() {
    // form based webcomponent, sync the hidden input value with the react component
    // we do not use the name attribute of the headless combobox component itself
    // as it adds nested input elements in case the options are not a string array
    if (this.hasAttribute("name")) {
      this.inputEl = this.closest("x-combobox")?.previousElementSibling;
      this.inputEl?.addEventListener("change", this.onValueChange);
    }

    // allow to define the event to trigger when the value changes
    this.event = this.dataset.event || "select";

    // early return if the component is already mounted / rendered
    if (this.__reactRoot) return;

    const mountPoint = document.createElement("div");
    this.appendChild(mountPoint);
    this.__reactRoot = ReactDOM.createRoot(mountPoint);
    this.render();
  }

  disconnectedCallback() {
    this.inputEl?.removeEventListener("change", this.onValueChange);
  }

  render() {
    // attributeChangedCallback triggered before connectedCallback
    if (!this.__reactRoot) {
      return;
    }

    let value = this.dataset.value;
    const options = JSON.parse(this.dataset.options);

    // add a prompt option if the prompt attribute is set
    if (this.dataset.prompt) {
      const promptOption = { label: this.dataset.prompt, value: "" };
      options.unshift(promptOption);
      if (value === undefined) {
        value = "";
      }
    }

    function coalesceValue(option) {
      if (Object.prototype.hasOwnProperty.call(option, "value")) {
        return option.value;
      }
      return option;
    }

    const onSelect = (option) => {
      if (coalesceValue(option) === value) {
        return;
      }

      // update the hidden input value if it exists
      // this is triggered if we use form component and the hidden input value changes
      if (this.inputEl) {
        this.inputEl.value = coalesceValue(option);
        // https://hexdocs.pm/phoenix_live_view/js-interop.html#triggering-phx-form-events-with-javascript
        this.inputEl.dispatchEvent(new Event("input", { bubbles: true }));
      }

      // trigger the select event if the EventBridge hook is available
      if (this.__pushEvent) {
        this.__pushEvent?.(this.event, { value: coalesceValue(option) });
      }
    };

    this.__reactRoot.render(
      <Combobox
        options={options}
        value={value}
        onSelect={onSelect}
        placeholder={this.dataset.placeholder}
        disabled={this.hasAttribute("disabled")}
      />
    );
  }

  // we pass prompt and placeholder as data attributes as we use phx-update="ignore"
  // on the input element to prevent the input value from being updated by live view
  // but we still want to update the prompt and placeholder in case we change the
  // language or the data from the server
  static get observedAttributes() {
    return ["data-options", "data-value", "data-prompt", "data-placeholder"];
  }

  // https://andyogo.github.io/custom-element-reactions-diagram/
  attributeChangedCallback(_attr, _value) {
    this.render();
  }

  // triggered if we use form component and the hidden input value changes
  onValueChange = () => this.render();
}
