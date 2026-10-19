import Link from "next/link";
import PixelLogo from "@/components/home/PixelLogo";
import { CAL_URL, EMAIL } from "@/lib/site";

export default function SiteFooter() {
  return (
    <footer className="vh-footer">
      <div className="vh-footer-grid">
        <div className="vh-footer-left">
          <p className="vh-head vh-footer-line">Let&apos;s build it.</p>
          <div className="vh-footer-actions">
            <Link href="/contact" className="vh-btn vh-btn-ink">
              Start a project
            </Link>
            <a href={CAL_URL} target="_blank" rel="noopener noreferrer" className="vh-btn vh-btn-ink-ghost">
              Book a call
            </a>
          </div>
          <ul className="vh-footer-links vh-mono">
            <li>
              <a href={`mailto:${EMAIL}`}>{EMAIL}</a>
            </li>
            <li>
              <Link href="/work">Work</Link>
            </li>
            <li>
              <Link href="/services">Services</Link>
            </li>
            <li>
              <Link href="/about">About</Link>
            </li>
            <li>
              <Link href="/contact">Contact</Link>
            </li>
          </ul>
        </div>
        <PixelLogo className="vh-footer-mark" title="Verj" />
      </div>
      <div className="vh-footer-legal vh-mono">
        <span>Verj Labs Inc. / Canada</span>
        <span>&copy; {new Date().getFullYear()}</span>
      </div>
    </footer>
  );
}
