/**
 * ResetOverlay
 *
 * Full-viewport flash shown when a `game:pile_reset` event fires.
 * Subscribes to `pileResetPending` in gameStore and auto-dismisses after
 * DISMISS_MS (matching the scatter animation duration in PileDisplay).
 *
 * pointer-events-none — never blocks user interaction.
 * Respects prefers-reduced-motion via Framer Motion.
 */
import { useEffect, useRef, useState } from "react";
import { AnimatePresence, motion, useReducedMotion } from "framer-motion";
import { useGameStore } from "@/store/gameStore";

// ─── Constants ────────────────────────────────────────────────────────────────

const DISMISS_MS = 700;

// ─── Component ────────────────────────────────────────────────────────────────

export function ResetOverlay() {
  const pileResetPending = useGameStore((s) => s.pileResetPending);
  const prefersReducedMotion = useReducedMotion();

  const [visible, setVisible] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    // Only trigger on the rising edge (false → true)
    if (!pileResetPending) return;

    // Cancel any in-flight timer before starting a new one
    if (timerRef.current) clearTimeout(timerRef.current);

    setVisible(true);

    // Timer lives in a ref — NOT returned as cleanup — so the store's null
    // reset cannot cancel it mid-flight.
    timerRef.current = setTimeout(() => {
      setVisible(false);
      timerRef.current = null;
    }, DISMISS_MS);
  }, [pileResetPending]);

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 pointer-events-none"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0, transition: { duration: 0.35 } }}
          aria-label="Pile reset"
          role="status"
          aria-live="assertive"
        >
          <motion.div
            style={{ color: "var(--color-hot-pink)" }}
            initial={prefersReducedMotion ? false : { scale: 0.6, opacity: 0 }}
            animate={prefersReducedMotion ? { opacity: 1 } : { scale: [0.6, 1.1, 1.0], opacity: 1 }}
            transition={{ duration: 0.2, type: "spring", stiffness: 500 }}
            className="flex flex-col items-center gap-3 select-none text-center"
          >
            <span
              className="font-[var(--font-heading)] font-bold text-7xl leading-none neon-glow-pink"
              data-testid="reset-overlay-title"
            >
              RESET!
            </span>
            <p className="font-[var(--font-heading)] text-xl text-white/70">pile cleared 🧹</p>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
