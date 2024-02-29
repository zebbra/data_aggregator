import { useState } from "react";
import { Combobox } from "@headlessui/react";

import { classNames, stringToId } from "../src/utils";

export default function ({
  options,
  value,
  onSelect,
  placeholder,
  disabled,
  errors,
}) {
  const [query, setQuery] = useState("");
  const grouped = Array.isArray(options) === false;

  // option is either a %{label, value} or a string
  function coalesceLabel(option) {
    if (Object.prototype.hasOwnProperty.call(option, "label")) {
      return option.label;
    }
    return option;
  }

  // option is either a %{label, value} or a string
  function coalesceValue(option) {
    if (Object.prototype.hasOwnProperty.call(option, "value")) {
      return option.value;
    }
    return option;
  }

  // clear the query when a new value is selected
  function onChange(event) {
    setQuery("");
    onSelect(event);
  }

  function findOption(option) {
    let result;

    function search(group_or_option) {
      if (Array.isArray(group_or_option)) {
        group_or_option.find(search);
      } else if (
        Object.prototype.hasOwnProperty.call(group_or_option, "options")
      ) {
        group_or_option.options.find(search);
      } else if (coalesceValue(group_or_option) === value) {
        result = group_or_option;
      }
    }

    search(option);
    return result;
  }

  const selected = grouped
    ? Object.values(options).flat().find(findOption)
    : findOption(options);

  function filter(option) {
    const result = [];

    function search(group_or_option, group_name) {
      if (Array.isArray(group_or_option)) {
        group_or_option.find((o) => search(o));
      } else if (
        Object.prototype.hasOwnProperty.call(group_or_option, "options")
      ) {
        group_or_option.options.find((o) =>
          search(o, coalesceLabel(group_or_option))
        );
      } else if (
        coalesceLabel(group_or_option)
          .toLowerCase()
          .includes(query.toLowerCase())
      ) {
        if (group_name) {
          const group = result.find((g) => g.label === group_name);
          if (group) {
            group.options.push(group_or_option);
          } else {
            result.push({ label: group_name, options: [group_or_option] });
          }
        } else {
          result.push(group_or_option);
        }
      }
    }

    search(option);
    return result;
  }

  function filterOptions() {
    if (grouped) {
      const result = {};

      // iterate over each group
      for (const group in options) {
        // filter out entries in the current group
        result[group] = filter(options[group]);

        // if the group is empty after filtering, remove it from result
        if (result[group].length === 0) {
          delete result[group];
        }
      }

      return result;
    }

    return filter(options);
  }

  const filteredOptions = query === "" ? options : filterOptions();

  return (
    <Combobox
      as="div"
      className="form-control w-full"
      value={selected}
      onChange={onChange}
      disabled={disabled}
    >
      <div className="relative">
        <div
          className={classNames(
            "flex items-center gap-x-2 input input-bordered relative pr-9",
            errors && "phx-feedback:input-error"
          )}
          disabled={disabled}
        >
          <Combobox.Button className="flex min-w-0 flex-1 justify-start">
            {({ open }) => (
              <Combobox.Input
                className="grow"
                onChange={(event) => setQuery(event.target.value)}
                displayValue={(option) => coalesceLabel(option)}
                placeholder={placeholder}
                onClick={(e) => open && e.stopPropagation()}
              />
            )}
          </Combobox.Button>
          <Combobox.Button
            as="span"
            className="hero-chevron-up-down-micro size-4 text-black-white shrink-0 absolute top-4 right-3 cursor-pointer"
            aria-hidden="true"
          />
        </div>

        {hasResults() && (
          <Combobox.Options className="absolute z-10 mt-1.5 max-h-60 w-full overflow-auto rounded-lg bg-base-100 pb-1 text-base-content shadow-lg border-black-white/10 border sm:text-sm no-scrollbar">
            <div className="h-1 w-full sticky top-0 bg-base-100 z-10" />
            {grouped
              ? renderGroups(filteredOptions)
              : renderOptions(filteredOptions)}
          </Combobox.Options>
        )}
      </div>
    </Combobox>
  );

  function hasResults() {
    if (grouped) {
      return Object.keys(filteredOptions).length > 0;
    }

    return filteredOptions.length > 0;
  }

  function renderGroups(groups) {
    return Object.keys(groups).map((group) =>
      renderGroup(group, groups[group])
    );
  }

  function renderGroup(label, options) {
    return (
      <ul key={label} role="group" aria-labelledby={stringToId(label)}>
        <li
          role="presentation"
          id={stringToId(label)}
          className="sticky top-1 bg-base-100 z-10 px-3 text-sm/6 py-1.5 font-bold text-base-content/60 border-b border-black-white/10 tracking-tighter pointer-events-none"
        >
          {label}
        </li>
        {renderOptions(options, true)}
      </ul>
    );
  }

  function renderOptions(options, indent = false) {
    return options.map((option) => {
      if (Object.prototype.hasOwnProperty.call(option, "options")) {
        return renderGroup(coalesceLabel(option), option.options);
      }
      return renderOption(option, indent);
    });
  }

  function renderOption(option, indent = false) {
    return (
      <Combobox.Option
        key={coalesceValue(option)}
        value={option}
        className={({ active }) =>
          classNames(
            "relative cursor-default select-none py-2 pr-9",
            active ? "bg-primary text-primary-content" : "text-base-content",
            indent ? "pl-6" : "pl-3"
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
              {coalesceLabel(option)}
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
}
