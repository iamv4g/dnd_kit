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
        faint: "rgb(var(--color-faint) / <alpha-value>)",
        line: "rgb(var(--color-line) / <alpha-value>)",
        accent: {
          DEFAULT: "rgb(var(--color-accent) / <alpha-value>)",
          deep: "rgb(var(--color-accent-deep) / <alpha-value>)",
        },
        // The remaining hues of the hero sweep. Reusing them as category
        // colours means any coloured dot on the page traces back to the image
        // at the top instead of being a new invention.
        sky: "rgb(var(--color-sky) / <alpha-value>)",
        apricot: "rgb(var(--color-apricot) / <alpha-value>)",
        mint: "rgb(var(--color-mint) / <alpha-value>)",
      },
      fontFamily: {
        // One grotesque family carries both display and UI.
        display: [
          '"Hanken Grotesk"',
          "ui-sans-serif",
          "system-ui",
          "sans-serif",
        ],
        sans: ['"Hanken Grotesk"', "ui-sans-serif", "system-ui", "sans-serif"],
        mono: ['"Geist Mono"', "ui-monospace", "SFMono-Regular", "monospace"],
      },
      boxShadow: {
        // Layered and blue-tinted; the values live in web/styles.tw.css so the
        // dark theme can restate them.
        lift: "var(--lift)",
        "lift-hi": "var(--lift-hi)",
        "lift-accent": "0 10px 26px -10px rgb(var(--color-accent-deep) / 0.7)",
      },
      borderRadius: {
        "4xl": "2rem",
        "5xl": "2.5rem",
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
        float: {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-6px)" },
        },
      },
      animation: {
        "fade-up": "fade-up 0.6s cubic-bezier(0.22, 1, 0.36, 1) both",
        "fade-in": "fade-in 0.6s ease both",
        // Release springs back rather than snapping — the settle of the motif.
        settle: "settle 0.5s cubic-bezier(0.34, 1.4, 0.64, 1) both",
        float: "float 5s ease-in-out infinite",
      },
      transitionTimingFunction: {
        spring: "cubic-bezier(0.34, 1.56, 0.64, 1)",
      },
    },
  },
  plugins: [],
};
