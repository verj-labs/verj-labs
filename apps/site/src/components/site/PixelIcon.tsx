export default function PixelIcon({ rows, className = "vh-svc-icon" }: { rows: string[]; className?: string }) {
  return (
    <svg className={className} viewBox="0 0 7 6" aria-hidden="true" shapeRendering="crispEdges">
      {rows.flatMap((r, y) =>
        r.split("").map((c, x) => (c === "1" ? <rect key={`${x}-${y}`} x={x} y={y} width="1" height="1" /> : null)),
      )}
    </svg>
  );
}
