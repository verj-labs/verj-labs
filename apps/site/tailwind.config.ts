import type { Config } from "tailwindcss";

export default {
  darkMode: "class",
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        bricolage: ["var(--font-bricolage)", "sans-serif"],
        outfit: ["var(--font-outfit)", "sans-serif"],
        // legacy aliases so old font-poppins/font-lato classes don't break
        poppins: ["var(--font-bricolage)", "sans-serif"],
        lato: ["var(--font-outfit)", "sans-serif"],
      },
      colors: {
        // ── new design tokens ──────────────────────────────
        bg: "#07070C",
        surface: "#0F0F1A",
        "surface-2": "#0A0A12",
        lime: "#D4F53C",
        "lime-dark": "#A8E000",
        "off-white": "#F2F0EA",
        // product / accent palette
        purple: "#8C5AFF",
        teal: "#1DD2A0",
        amber: "#FAB432",
        // ── verj namespace (legacy + updated values) ───────
        verj: {
          navy: "#07070C",
          surface: "#0F0F1A",
          purple: "#0F0F1A",
          lime: "#D4F53C",
          "lime-dark": "#A8E000",
          light: "#F2F0EA",
          text: "#F2F0EA",
          muted: "rgba(242,240,234,0.45)",
          // legacy color keys remapped to new palette
          violet: "#8C5AFF",
          blue: "#1DD2A0",
          coral: "#FAB432",
          green: "#D4F53C",
        },
        // shadcn compatibility
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        primary: { DEFAULT: "hsl(var(--primary))", foreground: "hsl(var(--primary-foreground))" },
        secondary: { DEFAULT: "hsl(var(--secondary))", foreground: "hsl(var(--secondary-foreground))" },
        muted: { DEFAULT: "hsl(var(--muted))", foreground: "hsl(var(--muted-foreground))" },
        accent: { DEFAULT: "hsl(var(--accent))", foreground: "hsl(var(--accent-foreground))" },
        destructive: { DEFAULT: "hsl(var(--destructive))", foreground: "hsl(var(--destructive-foreground))" },
        card: { DEFAULT: "hsl(var(--card))", foreground: "hsl(var(--card-foreground))" },
        popover: { DEFAULT: "hsl(var(--popover))", foreground: "hsl(var(--popover-foreground))" },
      },
      backgroundImage: {
        "gradient-lime": "linear-gradient(135deg, #D4F53C 0%, #A8E000 100%)",
        "gradient-lime-subtle": "linear-gradient(135deg, rgba(212,245,60,0.12) 0%, transparent 60%)",
        "gradient-purple-subtle": "linear-gradient(135deg, rgba(140,90,255,0.10) 0%, transparent 60%)",
      },
      animation: {
        "marquee": "marquee 35s linear infinite",
        "blink": "blink 2s ease-in-out infinite",
        "float": "float 6s ease-in-out infinite",
        "pulse-slow": "pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite",
      },
      keyframes: {
        marquee: {
          "0%": { transform: "translateX(0)" },
          "100%": { transform: "translateX(-50%)" },
        },
        blink: {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0.25" },
        },
        float: {
          "0%, 100%": { transform: "translateY(0px)" },
          "50%": { transform: "translateY(-12px)" },
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
} satisfies Config;
