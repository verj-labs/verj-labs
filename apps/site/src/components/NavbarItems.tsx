"use client";

import Link from "next/link";
import { Menu, X } from "lucide-react";

interface NavbarProps {
  isMenuOpen: boolean;
  setIsMenuOpen: (open: boolean) => void;
}

const navLinks = [
  { href: "/", label: "Home" },
  { href: "/portfolio", label: "Work" },
  { href: "/products", label: "Products" },
  { href: "/services", label: "Services" },
  { href: "/about", label: "About" },
];

const Navbar = ({ isMenuOpen, setIsMenuOpen }: NavbarProps) => {
  return (
    <>
      {/* Desktop */}
      <div className="hidden md:flex items-center gap-7">
        {navLinks.map((link) => (
          <Link
            key={link.href}
            href={link.href}
            className="text-[0.82rem] font-outfit font-normal text-off-white/45 hover:text-off-white transition-colors duration-200"
            style={{ letterSpacing: "0.01em" }}
          >
            {link.label}
          </Link>
        ))}
        <Link href="/contact" className="btn-primary text-[0.82rem] py-[0.55rem] px-[1.3rem]">
          Get Started
        </Link>
      </div>

      {/* Mobile toggle */}
      <div className="md:hidden">
        <button
          onClick={() => setIsMenuOpen(!isMenuOpen)}
          className="p-2 text-off-white/60 hover:text-off-white transition-colors"
          aria-label="Toggle menu"
        >
          {isMenuOpen ? <X size={22} /> : <Menu size={22} />}
        </button>
      </div>

      {/* Mobile menu */}
      {isMenuOpen && (
        <>
          <div
            className="md:hidden fixed inset-0 bg-bg/80 backdrop-blur-sm z-40"
            onClick={() => setIsMenuOpen(false)}
          />
          <div className="md:hidden fixed top-0 right-0 h-full w-72 glass-strong border-l border-white/05 z-50">
            <div className="flex flex-col h-full">
              <div className="flex items-center justify-between p-5 border-b border-white/05">
                <span className="font-bricolage font-extrabold text-lg text-off-white" style={{ letterSpacing: "-0.03em" }}>
                  Verj<span className="text-lime">.</span>
                </span>
                <button
                  onClick={() => setIsMenuOpen(false)}
                  className="p-1.5 text-off-white/50 hover:text-off-white transition-colors"
                >
                  <X size={20} />
                </button>
              </div>
              <div className="flex-1 px-5 py-6 space-y-1">
                {navLinks.map((link) => (
                  <Link
                    key={link.href}
                    href={link.href}
                    className="block px-3 py-3.5 text-sm font-outfit text-off-white/50 hover:text-off-white hover:bg-white/03 rounded-xl transition-all"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    {link.label}
                  </Link>
                ))}
              </div>
              <div className="p-5 border-t border-white/05">
                <Link
                  href="/contact"
                  className="btn-primary w-full justify-center text-sm"
                  onClick={() => setIsMenuOpen(false)}
                >
                  Get Started
                </Link>
              </div>
            </div>
          </div>
        </>
      )}
    </>
  );
};

export default Navbar;
