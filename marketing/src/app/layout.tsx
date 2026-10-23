import type { Metadata } from "next";
import { Archivo, Archivo_Black, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const display = Archivo_Black({ weight: "400", subsets: ["latin"], variable: "--display" });
const body = Archivo({ weight: ["400", "500", "700"], subsets: ["latin"], variable: "--body" });
const mono = JetBrains_Mono({ weight: ["500"], subsets: ["latin"], variable: "--mono" });

export const metadata: Metadata = {
  title: "Marketing pipeline",
  description: "Turn a brand kit and a brief into a 9:16 video.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={`${display.variable} ${body.variable} ${mono.variable}`}>{children}</body>
    </html>
  );
}
