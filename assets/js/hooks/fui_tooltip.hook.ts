import type {
  FlipOptions,
  Middleware,
  OffsetOptions,
  Placement,
  ShiftOptions,
} from "@floating-ui/dom";
import { arrow, computePosition, flip, offset, shift } from "@floating-ui/dom";

import { Hook, makeHook } from "./hook";

const PlacementMap: { [key: string]: Placement } = {
  top: "top",
  right: "right",
  bottom: "bottom",
  left: "left",
  "top-start": "top-start",
  "right-start": "right-start",
  "bottom-start": "bottom-start",
  "left-start": "left-start",
  "top-end": "top-end",
  "right-end": "right-end",
  "bottom-end": "bottom-end",
  "left-end": "left-end",
};

class FuiTooltipHook extends Hook {
  mounted(): void {
    this.run("mounted");
  }
  updated(): void {
    this.run("updated");
  }
  run(lifecycle: string): void {
    const hook = this;
    const tooltip = this.el;

    const triggerAriaDescription = tooltip.id;
    const triggerEl: HTMLElement | null = document.querySelector(
      `[aria-describedby="${triggerAriaDescription}"]`
    );

    // Early return if the trigger element is not found
    if (!triggerEl) {
      return;
    }

    // Arrow is optional
    const arrowElement: HTMLElement | null = tooltip.querySelector(
      `#${tooltip.id}_fui_arrow`
    );

    // Optionally move the tooltip to a different parent to overcome overflow issues
    const portalTargetId = tooltip.dataset.portal;
    const portalTarget: HTMLElement | null = portalTargetId
      ? document.getElementById(portalTargetId)
      : null;
    if (portalTarget && portalTarget.contains(tooltip) === false) {
      portalTarget.appendChild(tooltip);
    }

    const showClass = tooltip.dataset.show || "block";
    const hideClass = tooltip.dataset.hide || "hidden";

    function showTooltip() {
      tooltip.classList.remove(hideClass);
      tooltip.classList.add(showClass);
      update();
    }

    function hideTooltip() {
      tooltip.classList.remove(showClass);
      tooltip.classList.add(hideClass);
    }

    const middleware: Array<Middleware | null | undefined | false> = [];

    // hydrate offset options once if they exist
    if (
      tooltip.dataset.offsetOpts !== undefined &&
      hook["offsetOpts"] === undefined
    ) {
      if (tooltip.dataset.offsetOpts === "") {
        hook["offsetOpts"] = 0;
      } else if (isNaN(Number(tooltip.dataset.offsetOpts))) {
        hook["offsetOpts"] = JSON.parse(tooltip.dataset.offsetOpts);
      } else {
        hook["offsetOpts"] = Number(tooltip.dataset.offsetOpts);
      }
    }

    if (hook["offsetOpts"] !== undefined) {
      middleware.push(offset(hook["offsetOpts"]));
    }

    // hydrate flip options once if they exist
    if (
      tooltip.dataset.flipOpts !== undefined &&
      hook["flipOpts"] === undefined
    ) {
      if (tooltip.dataset.flipOpts === "") {
        hook["flipOpts"] = {};
      } else {
        hook["flipOpts"] = JSON.parse(tooltip.dataset.flipOpts);
      }
    }

    if (hook["flipOpts"] !== undefined) {
      middleware.push(flip(hook["flipOpts"]));
    }

    // hydrate shift options once if they exist
    if (
      tooltip.dataset.shiftOpts !== undefined &&
      hook["shiftOpts"] === undefined
    ) {
      if (tooltip.dataset.shiftOpts === "") {
        hook["shifOpts"] = {};
      } else {
        hook["shifOpts"] = JSON.parse(tooltip.dataset.shiftOpts);
      }
    }

    if (hook["shiftOpts"] !== undefined) {
      middleware.push(shift());
    }

    if (arrowElement) {
      middleware.push(arrow({ element: arrowElement }));
    }

    function update() {
      if (!triggerEl) {
        return;
      }

      computePosition(triggerEl, tooltip, {
        placement: PlacementMap[tooltip.dataset.placement || "top"],
        middleware,
      }).then(({ x, y, placement, middlewareData }) => {
        Object.assign(tooltip.style, {
          left: `${x}px`,
          top: `${y}px`,
        });

        if (!arrowElement) {
          return;
        }

        const { x: arrowX, y: arrowY } = middlewareData.arrow as any;

        const staticSide: any = {
          top: "bottom",
          right: "left",
          bottom: "top",
          left: "right",
        }[placement.split("-")[0]];

        Object.assign(arrowElement.style, {
          left: arrowX != null ? `${arrowX}px` : "",
          top: arrowY != null ? `${arrowY}px` : "",
          right: "",
          bottom: "",
          [staticSide]: "-4px",
        });
      });
    }

    const eventMap: Array<[string, () => void]> = [
      ["mouseenter", showTooltip],
      ["mouseleave", hideTooltip],
      ["focus", showTooltip],
      ["blur", hideTooltip],
    ];

    eventMap.forEach(([event, listener]) => {
      triggerEl.addEventListener(event, listener);
    });

    const showOnMount = tooltip.dataset.showOnMount;
    if (lifecycle === "mounted" && showOnMount === "true") {
      showTooltip();
    }
  }
}

const fuiTooltipHook = makeHook(FuiTooltipHook);
export default fuiTooltipHook;
