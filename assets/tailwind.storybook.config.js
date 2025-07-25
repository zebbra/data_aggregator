// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

import defaultConfig from "./tailwind.config";
defaultConfig.content.push("../storybook/**/*.*exs");
defaultConfig.important = ".data-aggregator";

module.exports = defaultConfig;
