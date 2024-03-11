import { TomOption } from "tom-select/dist/types/types";
import * as TomSelectUsedKeys from "tom-select/src/constants";
import TomSelect from "tom-select/dist/js/tom-select.base.js";
import TomSelect_checkbox_options from "tom-select/dist/js/plugins/checkbox_options";
import TomSelect_dropdown_input from "tom-select/dist/js/plugins/dropdown_input";
import TomSelect_remove_button from "tom-select/dist/js/plugins/remove_button.js";

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
  }

  updated(): void {
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

  init(el: HTMLElement): void {
    const options = JSON.parse(el.dataset.options || "{}");
    const plugins = JSON.parse(el.dataset.plugins || "[]");
    const globalOpts = window[el.dataset.globalOptions || "tomSelectDefaults"];
    const selectEl = el.querySelector("select.combobox");
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
  }
}

const comboboxHook = makeHook(ComboboxHook);

export default comboboxHook;
