import { useState } from "react";
import { Combobox } from "@headlessui/react";

import { classNames } from "../src/utils";

export default function ({ options, value, onSelect, placeholder, disabled }) {
  const [query, setQuery] = useState("");
  const grouped = Array.isArray(options) === false;

  function coalesceLabel(option) {
    return option.label || option;
  }

  function coalesceValue(option) {
    return option.value || option;
  }

  const selected = grouped
    ? Object.values(options)
        .flat()
        .find((option) => coalesceValue(option) === value)
    : options.find((option) => coalesceValue(option) === value);

  function filter(option) {
    return coalesceLabel(option).toLowerCase().includes(query.toLowerCase());
  }

  function filterOptions() {
    if (grouped) {
      const result = {};

      // Iterate over each group
      for (const group in options) {
        // Filter out entries in the current group
        result[group] = options[group].filter(filter);

        // If the group is empty after filtering, remove it from result
        if (result[group].length === 0) {
          delete result[group];
        }
      }

      return result;
    }

    return options.filter(filter);
  }

  const filteredOptions = query === "" ? options : filterOptions();

  function renderOption(option) {
    const key = coalesceValue(option);
    const label = coalesceLabel(option);
    return (
      <Combobox.Option
        key={key}
        value={option}
        className={({ active }) =>
          classNames(
            "relative cursor-default select-none py-2 pl-3 pr-9",
            active ? "bg-primary text-primary-content" : "text-base-content"
          )
        }
      >
        {({ active, selected }) => (
          <>
            <span
              className={classNames(
                "block truncate",
                selected && "font-semibold"
              )}
            >
              {label}
            </span>

            {selected && (
              <span
                className={classNames(
                  "absolute inset-y-0 right-0 flex items-center pr-4",
                  active ? "text-white" : "text-primary"
                )}
              >
                <span className="hero-check size-5" aria-hidden="true" />
              </span>
            )}
          </>
        )}
      </Combobox.Option>
    );
  }

  function renderOptions(options) {
    return options.map((option) => renderOption(option));
  }

  function renderGroup(label, options) {
    return (
      <div key={label}>
        <div className="sticky top-[-4px] mt-[-4px] bg-base-100 z-10 px-3 py-1.5 text-sm/6 font-semibold text-base-content/60 border-b border-black-white/10">
          <h3>{label}</h3>
        </div>
        {renderOptions(options)}
      </div>
    );
  }

  function renderGroups(groups) {
    return Object.keys(groups).map((group) =>
      renderGroup(group, groups[group])
    );
  }

  function hasResults() {
    if (grouped) {
      return Object.keys(filteredOptions).length > 0;
    }

    return filteredOptions.length > 0;
  }

  return (
    <Combobox
      as="div"
      className="form-control w-full"
      value={selected}
      onChange={onSelect}
      disabled={disabled}
    >
      <div className="relative">
        <div
          className="flex items-center gap-x-2 input input-bordered"
          disabled={disabled}
        >
          <Combobox.Input
            className="grow"
            onChange={(event) => setQuery(event.target.value)}
            displayValue={(option) => coalesceLabel(option)}
            placeholder={placeholder}
          />
          <Combobox.Button
            as="span"
            className="hero-chevron-up-down-mini size-5 text-base-content/50"
            aria-hidden="true"
          />
        </div>

        {hasResults() && (
          <Combobox.Options className="absolute z-10 mt-1.5 max-h-60 w-full overflow-auto rounded-md bg-base-100 py-1 text-base-content shadow-lg border-black-white/10 border sm:text-sm no-scrollbar">
            {grouped
              ? renderGroups(filteredOptions)
              : renderOptions(filteredOptions)}
          </Combobox.Options>
        )}
      </div>
    </Combobox>
  );
}
