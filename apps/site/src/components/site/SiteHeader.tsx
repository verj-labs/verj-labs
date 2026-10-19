import Link from "next/link";
import PixelLogo from "@/components/home/PixelLogo";
import { CAL_URL } from "@/lib/site";

const LINKS = [
  { href: "/work", label: "Work" },
  { href: "/services", label: "Services" },
  { href: "/about", label: "About" },
  { href: "/contact", label: "Contact" },
];

export default function SiteHeader() {
  return (
    <header className="vh-nav">
      <Link href="/" className="vh-wordmark" aria-label="Verj Labs home">
        <PixelLogo className="vh-nav-logo" />
        <span className="vh-mono">Labs</span>
      </Link>
      <nav aria-label="Main" className="vh-mono vh-nav-links">
        {LINKS.map((l) => (
          <Link key={l.href} href={l.href}>
            {l.label}
          </Link>
        ))}
      </nav>
      <a href={CAL_URL} target="_blank" rel="noopener noreferrer" className="vh-btn vh-btn-sm vh-nav-cta">
        Book a call
      </a>
      <details className="vh-menu">
        <summary className="vh-mono" aria-label="Menu">
          Menu
        </summary>
        <div className="vh-menu-panel vh-mono">
          {LINKS.map((l) => (
            <Link key={l.href} href={l.href}>
              {l.label}
            </Link>
          ))}
          <a href={CAL_URL} target="_blank" rel="noopener noreferrer">
            Book a call
          </a>
        </div>
      </details>
    </header>
  );
}
