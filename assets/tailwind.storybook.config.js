// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const defaultConfig = require("./tailwind.config");
defaultConfig.content.push("../storybook/**/*.*exs");
defaultConfig.important = ".data-aggregator";

module.exports = defaultConfig;
