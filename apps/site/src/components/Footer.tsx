import Link from "next/link";

const Footer = () => {
  return (
    <footer className="border-t border-white/[0.06] mt-auto">
      <div className="max-w-7xl mx-auto px-6 py-7 flex flex-col sm:flex-row justify-between items-center gap-4">
        {/* Logo */}
        <span
          className="font-bricolage font-extrabold text-[1.05rem] text-off-white"
          style={{ letterSpacing: "-0.02em" }}
        >
          Verj<em className="not-italic text-lime">.</em>
        </span>

        {/* Meta */}
        <span className="text-[0.72rem] font-outfit text-off-white/22 text-center">
          Verj Labs Inc.&nbsp;&nbsp;·&nbsp;&nbsp;© {new Date().getFullYear()}
        </span>

        {/* Links */}
        <div className="flex gap-6">
          {[
            { href: "/portfolio", label: "Work" },
            { href: "/services", label: "Services" },
            { href: "/about", label: "About" },
            { href: "mailto:hello@verjlabs.com", label: "hello@verjlabs.com" },
          ].map((l) => (
            <Link
              key={l.href}
              href={l.href}
              className="text-[0.75rem] font-outfit text-off-white/30 hover:text-off-white transition-colors duration-200"
            >
              {l.label}
            </Link>
          ))}
        </div>
      </div>
    </footer>
  );
};

export default Footer;
