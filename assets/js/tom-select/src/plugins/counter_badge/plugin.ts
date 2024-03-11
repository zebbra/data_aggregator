import type TomSelect from "tom-select";
import { getDom } from "tom-select/src/vanilla";

export default function (this: TomSelect) {
  this.hook("after", "setupTemplates", () => {
    const originOptionRenderer = this.settings.render.option;

    this.settings.render.option = (data, escape_html) => {
      const rendered = getDom(
        originOptionRenderer.call(this, data, escape_html)
      );
      const badge = document.createElement("span");
      const count = data.$option.hasAttribute("count")
        ? data.$option.getAttribute("count")
        : "";

      badge.className = "ml-auto pl-2 min-w-6 text-right";
      badge.textContent = escape_html(count);
      rendered.appendChild(badge);
      return rendered;
    };
  });
}
