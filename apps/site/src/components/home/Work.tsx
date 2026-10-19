import Link from "next/link";
import { WORK } from "@/lib/work";

/** Text-led list of case studies. Each row links to its case study. */
export default function Work() {
  return (
    <ul className="vh-work-list">
      {WORK.map((w) => (
        <li key={w.slug}>
          <Link href={`/work/${w.slug}`} className="vh-work-row">
            <span className="vh-mono vh-work-id">{w.id}</span>
            <span className="vh-work-main">
              <span className="vh-work-name">{w.name}</span>
              <span className="vh-work-tag">{w.tagline}</span>
              <span className="vh-mono vh-work-meta">{w.industry}</span>
            </span>
            <span className="vh-work-side">
              <span className="vh-mono vh-status" data-status={w.status}>
                {w.status}
              </span>
              <span className="vh-mono vh-work-go">Case study &rarr;</span>
            </span>
          </Link>
        </li>
      ))}
    </ul>
  );
}
