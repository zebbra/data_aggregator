import * as ReactDOM from "react-dom/client";
import Combobox from "./Combobox";

// https://reactjs.org/docs/web-components.html#using-react-in-your-web-components
export default class ComboboxWebcomponent extends HTMLElement {
  connectedCallback() {
    const mountPoint = document.createElement("div");
    this.appendChild(mountPoint);
    this.__reactRoot = ReactDOM.createRoot(mountPoint);

    // form based webcomponent
    if (this.hasAttribute("name")) {
      const inputId = this.getAttribute("id");
      this.inputEl = document.querySelector(`input[input-id="${inputId}"]`);
      this.inputEl.addEventListener("change", this.onValueChange);
    }

    this.render();
  }

  disconnectedCallback() {
    this.inputEl.removeEventListener("change", this.onValueChange);
  }

  render() {
    // attributeChangedCallback triggered before connectedCallback
    if (!this.__reactRoot) {
      return;
    }

    const options = JSON.parse(this.dataset.options);
    const value = this.inputEl
      ? this.inputEl.getAttribute("value")
      : this.dataset.value;
    const placeholder = this.dataset.placeholder;
    const disabled = this.hasAttribute("disabled");

    const onSelect = ({ value }) => {
      if (this.inputEl) {
        this.inputEl.value = value;
        // https://hexdocs.pm/phoenix_live_view/js-interop.html#triggering-phx-form-events-with-javascript
        this.inputEl.dispatchEvent(new Event("input", { bubbles: true }));
      } else {
        this.__pushEvent?.("select", { value });
      }
    };

    this.__reactRoot.render(
      <Combobox
        options={options}
        value={value}
        onSelect={onSelect}
        placeholder={placeholder}
        disabled={disabled}
      />
    );
  }

  static get observedAttributes() {
    return ["data-options", "data-value", "data-placeholder"];
  }

  // https://andyogo.github.io/custom-element-reactions-diagram/
  attributeChangedCallback(attr, value) {
    this.render();
  }

  // triggered if we use form component and the hidden input value changes
  onValueChange = () => this.render();
}
