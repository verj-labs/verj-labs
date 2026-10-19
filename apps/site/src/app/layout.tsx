import type { Metadata } from "next";
import { Archivo, Archivo_Black, JetBrains_Mono } from "next/font/google";
import "./site.css";
import SiteHeader from "@/components/site/SiteHeader";
import SiteFooter from "@/components/site/SiteFooter";

const display = Archivo_Black({ weight: "400", subsets: ["latin"], variable: "--vh-display", display: "swap" });
const text = Archivo({ weight: ["400", "500", "700"], subsets: ["latin"], variable: "--vh-text", display: "swap" });
// taste-skill-ignore: mono is used for small labels and nothing else
const code = JetBrains_Mono({ weight: ["400", "500", "700"], subsets: ["latin"], variable: "--vh-code", display: "swap" });

export const metadata: Metadata = {
  title: { default: "Verj Labs | Software studio", template: "%s | Verj Labs" },
  description:
    "Verj Labs is a Canadian software studio. We design, build and launch products, websites, mobile apps and AI for businesses.",
  icons: {
    icon: [
      { url: "/favicon/verj-pixel.svg", type: "image/svg+xml" },
      { url: "/favicon/favicon-16x16.png", sizes: "16x16", type: "image/png" },
      { url: "/favicon/favicon-32x32.png", sizes: "32x32", type: "image/png" },
      { url: "/favicon/favicon.ico", sizes: "any" },
    ],
    apple: [{ url: "/favicon/apple-touch-icon.png", sizes: "180x180", type: "image/png" }],
  },
  manifest: "/favicon/site.webmanifest",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={`vh ${display.variable} ${text.variable} ${code.variable}`}>
        <SiteHeader />
        <main>{children}</main>
        <SiteFooter />
      </body>
    </html>
  );
}
