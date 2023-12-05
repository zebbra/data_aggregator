// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const colors = require("tailwindcss/colors");
const fs = require("fs");
const path = require("path");
const themes = require("daisyui/src/theming/themes");

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./js/**/*.js",
    "./js/**/*.ts",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex",
  ],

  // DaisyUI config
  daisyui: {
    // Overrides to match the TailwindUI look
    themes: [
      {
        light: {
          ...themes.light,
          primary: colors.indigo["600"],
          "primary-content": colors.indigo["50"],
          secondary: colors.purple["600"],
          "secondary-content": colors.purple["50"],
          accent: colors.pink["600"],
          "accent-content": colors.pink["50"],
          success: colors.green["600"],
          "success-content": colors.green["50"],
          warning: colors.amber["600"],
          "warning-content": colors.amber["50"],
          error: colors.red["600"],
          "error-content": colors.red["50"],
          info: colors.blue["600"],
          "info-content": colors.blue["50"],
          "--rounded-box": "0.5rem",
          "--rounded-btn": "0.375rem",
        },

        dark: {
          ...themes.dark,
          primary: colors.indigo["600"],
          "primary-content": colors.indigo["50"],
          secondary: colors.purple["600"],
          "secondary-content": colors.purple["50"],
          accent: colors.pink["600"],
          "accent-content": colors.pink["50"],
          success: colors.green["600"],
          "success-content": colors.green["50"],
          warning: colors.amber["600"],
          "warning-content": colors.amber["50"],
          error: colors.red["600"],
          "error-content": colors.red["50"],
          info: colors.blue["600"],
          "info-content": colors.blue["50"],
          "--rounded-box": "0.5rem",
          "--rounded-btn": "0.375rem",
        },
      },
    ],
  },

  plugins: [
    // Default typography styles
    // require("@tailwindcss/typography"),

    // DaisyUI
    require("daisyui"),

    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", [
        ".phx-no-feedback&",
        ".phx-no-feedback &",
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-feedback", [
        ".form-control:not(.phx-no-feedback) &",
        ".form-control:not(.phx-no-feedback)&",
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ]),
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `Components.Icon.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "./vendor/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: theme("spacing.5"),
              height: theme("spacing.5"),
            };
          },
        },
        { values },
      );
    }),
  ],
};
