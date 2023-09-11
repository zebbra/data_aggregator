type ColorModeColor = "system" | "dark" | "light";
declare global {
  interface Window {
    ColorMode: {
      value: ColorModeColor;
      preference: ColorModeColor;
      toggleColorScheme: (value: ColorModeColor) => void;
    };
  }
}

const ColorMode = {
  mounted() {
    this.el.addEventListener("toggle-color-mode", () => {
      if (window.ColorMode.value === "dark") {
        window.ColorMode.toggleColorScheme("light");
      } else {
        window.ColorMode.toggleColorScheme("dark");
      }
    });
  },
};

export default ColorMode;
