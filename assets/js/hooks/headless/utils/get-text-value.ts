import { ref, Ref } from "@vue/reactivity";

import { dom } from "../utils/dom";

export function useTextValue(element: Ref<HTMLElement | null>) {
  const cacheKey = ref<string>("");
  const cacheValue = ref<string>("");

  return () => {
    const el = dom(element);
    if (!el) return "";

    // Check for a cached version
    const currentKey = el.innerText;
    if (cacheKey.value === currentKey) {
      return cacheValue.value;
    }

    // Calculate the value
    const value = getTextValue(el).trim().toLowerCase();
    cacheKey.value = currentKey;
    cacheValue.value = value;
    return value;
  };
}

const emojiRegex =
  /([\u2700-\u27BF]|[\uE000-\uF8FF]|\uD83C[\uDC00-\uDFFF]|\uD83D[\uDC00-\uDFFF]|[\u2011-\u26FF]|\uD83E[\uDD10-\uDDFF])/g;

function getTextContents(element: HTMLElement): string {
  // Using innerText instead of textContent because:
  //
  // > textContent gets the content of all elements, including <script> and <style> elements. In
  // > contrast, innerText only shows "human-readable" elements.
  // >
  // > — https://developer.mozilla.org/en-US/docs/Web/API/Node/textContent#differences_from_innertext
  const currentInnerText = element.innerText ?? "";

  // Remove all the elements that shouldn't be there.
  //
  // [hidden]       — The user doesn't see it
  // [aria-hidden]  — The screen reader doesn't see it
  // [role="img"]   — Even if it is text, it is used as an image
  //
  // This is probably the slowest part, but if you want compconste control over the text value, then
  // it is better to set an `aria-label` instead.
  const copy = element.cloneNode(true);
  if (!(copy instanceof HTMLElement)) {
    return currentInnerText;
  }

  let dropped = false;
  // Drop the elements that shouldn't be there.
  for (const child of copy.querySelectorAll(
    '[hidden],[aria-hidden],[role="img"]'
  )) {
    child.remove();
    dropped = true;
  }

  // Now that the elements are removed, we can get the innerText such that we can strip the emojis.
  let value = dropped ? copy.innerText ?? "" : currentInnerText;

  // Check if it contains some emojis or not, if so, we need to remove them
  // because ideally we work with simple text values.
  //
  // Ideally we can use the much simpler RegEx: /\p{Extended_Pictographic}/u
  // but we can't rely on this yet, so we use the more complex one.
  if (emojiRegex.test(value)) {
    value = value.replace(emojiRegex, "");
  }

  return value;
}

export function getTextValue(element: HTMLElement): string {
  // Try to use the `aria-label` first
  const label = element.getAttribute("aria-label");
  if (typeof label === "string") return label.trim();

  // Try to use the `aria-labelledby` second
  const labelledby = element.getAttribute("aria-labelledby");
  if (labelledby) {
    // aria-labelledby can be a space-separated list of IDs, so we need to split them up and
    // combine them into a single string.
    const labels = labelledby
      .split(" ")
      .map((labelledby) => {
        const labelEl = document.getElementById(labelledby);
        if (labelEl) {
          const label = labelEl.getAttribute("aria-label");
          // Try to use the `aria-label` first (of the referenced element)
          if (typeof label === "string") return label.trim();

          // This time, the `aria-labelledby` isn't used anymore (in Safari), so we just have to
          // look at the contents itself.
          return getTextContents(labelEl).trim();
        }

        return null;
      })
      .filter(Boolean);

    if (labels.length > 0) return labels.join(", ");
  }

  // Try to use the text contents of the element itself
  return getTextContents(element).trim();
}
