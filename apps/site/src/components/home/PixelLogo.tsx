// High-resolution bitmap wordmark: 89 x 21 pixels, generated from a heavy grotesque.
// Each run of lit pixels is one rectangle in a single path.
export const LOGO_COLS = 89;
export const LOGO_ROWS = 21;
const PATH = "M0 0h7v1h-7zM16 0h7v1h-7zM26 0h18v1h-18zM48 0h15v1h-15zM82 0h7v1h-7zM1 1h6v1h-6zM16 1h6v1h-6zM26 1h18v1h-18zM48 1h17v1h-17zM82 1h7v1h-7zM1 2h7v1h-7zM15 2h7v1h-7zM26 2h18v1h-18zM48 2h18v1h-18zM82 2h7v1h-7zM1 3h7v1h-7zM15 3h7v1h-7zM26 3h18v1h-18zM48 3h19v1h-19zM82 3h7v1h-7zM2 4h6v1h-6zM15 4h6v1h-6zM26 4h18v1h-18zM48 4h7v1h-7zM59 4h8v1h-8zM82 4h7v1h-7zM2 5h7v1h-7zM15 5h6v1h-6zM26 5h7v1h-7zM48 5h7v1h-7zM60 5h7v1h-7zM82 5h7v1h-7zM3 6h6v1h-6zM14 6h6v1h-6zM26 6h7v1h-7zM48 6h7v1h-7zM61 6h6v1h-6zM82 6h7v1h-7zM3 7h6v1h-6zM14 7h6v1h-6zM26 7h7v1h-7zM48 7h7v1h-7zM60 7h7v1h-7zM82 7h7v1h-7zM3 8h7v1h-7zM14 8h6v1h-6zM26 8h17v1h-17zM48 8h7v1h-7zM57 8h10v1h-10zM82 8h7v1h-7zM4 9h6v1h-6zM13 9h6v1h-6zM26 9h17v1h-17zM48 9h18v1h-18zM82 9h7v1h-7zM4 10h6v1h-6zM13 10h6v1h-6zM26 10h17v1h-17zM48 10h17v1h-17zM82 10h7v1h-7zM4 11h7v1h-7zM13 11h6v1h-6zM26 11h17v1h-17zM48 11h15v1h-15zM82 11h7v1h-7zM5 12h6v1h-6zM12 12h6v1h-6zM26 12h7v1h-7zM48 12h16v1h-16zM82 12h7v1h-7zM5 13h6v1h-6zM12 13h6v1h-6zM26 13h7v1h-7zM48 13h7v1h-7zM57 13h8v1h-8zM74 13h4v1h-4zM82 13h7v1h-7zM6 14h12v1h-12zM26 14h7v1h-7zM48 14h7v1h-7zM58 14h7v1h-7zM72 14h6v1h-6zM82 14h7v1h-7zM6 15h11v1h-11zM26 15h7v1h-7zM48 15h7v1h-7zM59 15h7v1h-7zM72 15h6v1h-6zM82 15h6v1h-6zM6 16h11v1h-11zM26 16h18v1h-18zM48 16h7v1h-7zM59 16h8v1h-8zM72 16h16v1h-16zM7 17h9v1h-9zM26 17h19v1h-19zM48 17h7v1h-7zM60 17h7v1h-7zM73 17h15v1h-15zM7 18h9v1h-9zM26 18h19v1h-19zM48 18h7v1h-7zM60 18h8v1h-8zM73 18h14v1h-14zM8 19h8v1h-8zM26 19h19v1h-19zM48 19h7v1h-7zM61 19h7v1h-7zM74 19h12v1h-12zM8 20h7v1h-7zM26 20h18v1h-18zM48 20h7v1h-7zM61 20h8v1h-8zM76 20h9v1h-9z";

export default function PixelLogo({ className, title }: { className?: string; title?: string }) {
  return (
    <svg
      className={className}
      viewBox={`0 0 ${LOGO_COLS} ${LOGO_ROWS}`}
      fill="currentColor"
      shapeRendering="crispEdges"
      role={title ? "img" : undefined}
      aria-label={title}
      aria-hidden={title ? undefined : true}
    >
      <path d={PATH} />
    </svg>
  );
}
