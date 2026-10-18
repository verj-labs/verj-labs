import '@testing-library/jest-dom';

// jsdom does not implement window.matchMedia — stub it so libraries like
// sonner that rely on it (e.g. for prefers-reduced-motion) don't throw.
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: (query: string): MediaQueryList => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => false,
  }),
});
