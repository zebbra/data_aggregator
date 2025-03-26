import type { TomInput, TomOption } from "tom-select/dist/esm/types/core.js";
import * as TomSelectUsedKeys from "tom-select/dist/esm/constants.js";
import TomSelect from "tom-select/base";
import TomSelect_checkbox_options from "tom-select/plugins/checkbox_options/plugin.js";
import TomSelect_dropdown_input from "tom-select/plugins/dropdown_input/plugin.js";
import TomSelect_remove_button from "tom-select/plugins/remove_button/plugin.js";
import { autoUpdate, computePosition, offset } from "@floating-ui/dom";

import { Hook, makeHook } from "./hook";
import TomSelect_badge_counter from "../tom-select/src/plugins/counter_badge/plugin";

TomSelect.define("checkbox_options", TomSelect_checkbox_options);
TomSelect.define("dropdown_input", TomSelect_dropdown_input);
TomSelect.define("remove_button", TomSelect_remove_button);
TomSelect.define("counter_badge", TomSelect_badge_counter);

const KEY_CODES = Object.values(TomSelectUsedKeys).filter(
  (value) => typeof value === "number" && value !== 65
) as number[];

class ComboboxHook extends Hook {
  private tomSelect: any;

  mounted(): void {
    this.init(this.el);

    this.handleEvent("combobox:reset", (payload) => {
      if (!this.tomSelect) return;

      const identificator = (
        this.el.querySelector("input[type='hidden']") as HTMLElement
      )?.dataset.identificator;

      if (
        identificator !== payload.name &&
        !this.el.querySelector(`input[name='${payload.name}']`)
      ) {
        return;
      }

      const value = payload.value === null ? "" : payload.value;
      if (this.tomSelect.getValue() === value) return;

      this.tomSelect.setValue(value);
    });
  }

  updated(): void {
    const input = this.el.querySelector("input[type='hidden']")!;
    const selectEl = this.el.querySelector("select.combobox")!;

    // This might be the case when the combobox is inside a form and the form structure
    // changes (for example for embedded resources which are added or removed dynamically)
    if (
      input.getAttribute("name") !== selectEl.getAttribute("name") &&
      `${input.getAttribute("name")}[]` !== selectEl.getAttribute("name")
    ) {
      selectEl.setAttribute("name", input.getAttribute("name")!);
    }

    // If the options have changed, destroy the TomSelect instance and re-initialize it with the new options.
    const latestSelect = this.el.querySelector("select.combobox-latest");
    const initialSelect = this.el.querySelector("select.combobox");

    const latestOptions = latestSelect?.querySelectorAll("option");
    const initialOptions = initialSelect?.querySelectorAll("option");

    // Convert latestOptions and initialOptions to arrays
    // Filter out any empty options as they might lead to
    // the TomSelect instance being destroyed and re-initialized
    // in case we use event delegation to update the selected option
    const latestOptionsArray = Array.from(latestOptions || []).filter(
      (option) => option.value !== ""
    );
    const initialOptionsArray = Array.from(initialOptions || []).filter(
      (option) => option.value !== ""
    );

    // Sort the arrays by their values
    latestOptionsArray.sort((a, b) => a.value.localeCompare(b.value));
    initialOptionsArray.sort((a, b) => a.value.localeCompare(b.value));

    if (latestOptionsArray && initialOptionsArray) {
      if (latestOptionsArray.length !== initialOptionsArray.length) {
        this.reinitialize(initialSelect, latestSelect);
        return;
      }

      for (let i = 0; i < latestOptionsArray.length; i++) {
        const option1 = latestOptionsArray[i];
        const option2 = initialOptionsArray[i];

        if (
          option1.label !== option2.label ||
          option1.value !== option2.value
        ) {
          this.reinitialize(initialSelect, latestSelect);
          break;
        }
      }
    }
  }

  destroyed(): void {
    // Hide the first div child of this.el:
    this.el.querySelector(".combobox-wrapper")?.classList.add("hidden");
    this.tomSelect && this.tomSelect.destroy();

    const hook = this;
    if (typeof hook["cleanup"] === "function") {
      hook["cleanup"]();
    }
  }

  reinitialize(
    initialSelect: Element | null,
    latestSelect: Element | null
  ): void {
    if (this.tomSelect) {
      this.tomSelect.destroy();
    }
    if (initialSelect && latestSelect) {
      initialSelect.innerHTML = latestSelect.innerHTML;
    }
    this.init(this.el);
  }

  async init(el: HTMLElement): Promise<void> {
    const options = JSON.parse(el.dataset.options || "{}");
    const plugins = JSON.parse(el.dataset.plugins || "[]");
    const globalOpts = window[el.dataset.globalOptions || "tomSelectDefaults"];
    const selectEl = el.querySelector("select.combobox") as TomInput;
    const remoteOptionsEventName = el.dataset.remoteOptionsEventName;

    const addText = options.addText || "Add";
    const noResultsText = options.noResultsText || "No results found for";
    const render = {
      option: function (data: TomOption, escape: (input: string) => string) {
        return `<div><span class="option-text">${escape(
          data[this.settings.labelField]
        )}</span></div>`;
      },
      option_create: function (
        data: TomOption,
        escape: (input: string) => string
      ) {
        return `<div class="create">${addText} <strong>${escape(
          data.input
        )} </strong>&hellip;</div>`;
      },
      no_results: function (
        data: TomOption,
        escape: (input: string) => string
      ) {
        return `<div class="no-results">${noResultsText} "${escape(
          data.input
        )}"</div>`;
      },
    };

    const tomSelectOptions: TomOption = {
      plugins,
      ...options,
      ...globalOpts,
      render,
      controlInput: `<input type="text" autocomplete="off" size="1" phx-change='[["_",{"to":"#_"}]]' />`,
    };

    if (remoteOptionsEventName) {
      tomSelectOptions.load = (
        query: string,
        callback: (
          result: Record<string, Array<{ text: string; value: any }>>
        ) => {}
      ) => {
        // This calls the Phoenix Live View. Expects the results in this format: %{results: [{text: "text", value: "value"}]
        this.pushEvent(remoteOptionsEventName, query, (payload) => {
          const resultsJSON = payload.results.map(({ text, value }) => ({
            text,
            value,
          }));

          callback(resultsJSON);
        });
      };
    }

    this.tomSelect = new TomSelect(selectEl, tomSelectOptions);

    // register the change event if the combobox has an on-change attribute
    // and push the event to the LiveView
    // if the combobox has a phx-target attribute, push the event to the specified target
    if (this.el.hasAttribute("on-change")) {
      const eventName = this.el.getAttribute("on-change") || "change";
      const eventTarget = this.el.getAttribute("phx-target");

      this.tomSelect.on("change", (value: null | string | Array<string>) => {
        if (value === "") return;
        eventTarget
          ? this.pushEventTo(eventTarget, eventName, { value }, () => {})
          : this.pushEvent(eventName, { value }, () => {});
      });
    }

    // open dropdown on keydown
    this.tomSelect.control.addEventListener("keydown", (e: KeyboardEvent) => {
      // prevent the default behavior of the keydown event
      if (
        // tom-select already handles these keys
        KEY_CODES.includes(e.keyCode) ||
        ["Meta", "Control", "Shift", "Alt"].includes(e.key) ||
        // select all
        ((e.ctrlKey || e.metaKey) && e.keyCode === 65)
      ) {
        return;
      }
      this.tomSelect.open();
    });

    el.querySelector(".combobox-wrapper")?.classList.remove("opacity-0");

    if (el.dataset.portal) {
      const targetId = el.dataset.portal;
      if (!targetId) {
        console.warn("No portal target id specified");
        return;
      }

      const portalTarget = document.getElementById(targetId) as HTMLElement;

      if (!portalTarget) {
        console.warn(`Could not find portal target with id: ${targetId}`);
        return;
      }

      const hook = this;
      const attachToEl = el.querySelector(".combobox-wrapper") as HTMLElement;
      const floatingEl = el.querySelector(".ts-dropdown") as HTMLElement;

      if (!floatingEl) {
        console.warn("Could not find floating element");
        return;
      }

      if (!attachToEl) {
        console.warn("Could not find attachTo element");
        return;
      }

      await Promise.all(
        attachToEl
          .getAnimations()
          .filter((a) => a instanceof CSSTransition)
          .map((a) => new Promise((resolve) => (a.onfinish = resolve)))
      );

      // ensure to set the placement to top if the data-ts-dropup attribute is set to true
      if (
        el.dataset.ts_dropup === "true" &&
        el.dataset.placement === undefined
      ) {
        el.dataset.placement = "top";
        floatingEl.classList.add("dropup");
      } else {
        floatingEl.classList.add("dropdown");
      }

      // ensure the floating element is attached to the portal root
      portalTarget.appendChild(floatingEl);

      // hydrate offset options once if they exist
      if (el.dataset.floatOffset && hook["floatOffsetOpts"] === undefined) {
        hook["floatOffsetOpts"] = JSON.parse(el.dataset.floatOffset);
      }

      if (attachToEl) {
        const middleware = hook["floatOffsetOpts"]
          ? [offset(hook["floatOffsetOpts"])]
          : [];
        const floatOpts: any = {
          placement: el.dataset.placement || "bottom",
          middleware,
        };

        const updatePosition = () =>
          computePosition(attachToEl, floatingEl, floatOpts).then(
            ({ x, y }) => {
              const parentWidth = attachToEl.offsetWidth;
              Object.assign(floatingEl.style, {
                width: `${parentWidth}px`,
                left: `${x}px`,
                top: `${y}px`,
              });
            }
          );

        updatePosition();

        // When the floating element is open on the screen
        hook["cleanup"] = autoUpdate(attachToEl, floatingEl, updatePosition);
      }
    }
  }
}

const comboboxHook = makeHook(ComboboxHook);

export default comboboxHook;
