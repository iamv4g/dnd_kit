/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: "class",
  content: ["./lib/**/*.dart", "./web/**/*.dart"],
  theme: {
    extend: {
      colors: {
        // Driven by CSS variables in web/styles.tw.css so a single class
        // (e.g. `bg-paper`, `text-ink`) adapts to light/dark automatically.
        paper: "rgb(var(--color-paper) / <alpha-value>)",
        surface: "rgb(var(--color-surface) / <alpha-value>)",
        raised: "rgb(var(--color-raised) / <alpha-value>)",
        ink: "rgb(var(--color-ink) / <alpha-value>)",
        muted: "rgb(var(--color-muted) / <alpha-value>)",
        line: "rgb(var(--color-line) / <alpha-value>)",
        accent: {
          DEFAULT: "rgb(var(--color-accent) / <alpha-value>)",
          deep: "rgb(var(--color-accent-deep) / <alpha-value>)",
        },
      },
      fontFamily: {
        serif: ['"Newsreader"', "ui-serif", "Georgia", "serif"],
        sans: ['"Hanken Grotesk"', "ui-sans-serif", "system-ui", "sans-serif"],
        mono: ['"Geist Mono"', "ui-monospace", "SFMono-Regular", "monospace"],
      },
      boxShadow: {
        lift: "0 18px 40px -12px rgb(31 30 29 / 0.18)",
        "lift-accent": "0 18px 44px -10px rgb(217 119 87 / 0.45)",
      },
      keyframes: {
        "fade-up": {
          "0%": { opacity: "0", transform: "translateY(18px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        // Opacity-only entrance: leaves no residual transform, so a
        // `position: fixed` drag overlay nested inside still anchors to the
        // viewport (a transform would create a containing block).
        "fade-in": {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
        settle: {
          "0%": { opacity: "0", transform: "translateY(-10px) rotate(-1.5deg)" },
          "60%": { transform: "translateY(2px) rotate(0.4deg)" },
          "100%": { opacity: "1", transform: "translateY(0) rotate(0)" },
        },
        "pulse-drop": {
          "0%, 100%": { borderColor: "rgb(var(--color-accent) / 0.45)" },
          "50%": { borderColor: "rgb(var(--color-accent) / 1)" },
        },
        float: {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-6px)" },
        },
      },
      animation: {
        "fade-up": "fade-up 0.6s cubic-bezier(0.22, 1, 0.36, 1) both",
        "fade-in": "fade-in 0.6s ease both",
        settle: "settle 0.5s cubic-bezier(0.22, 1, 0.36, 1) both",
        "pulse-drop": "pulse-drop 1.4s ease-in-out infinite",
        float: "float 5s ease-in-out infinite",
      },
    },
  },
  plugins: [],
};
