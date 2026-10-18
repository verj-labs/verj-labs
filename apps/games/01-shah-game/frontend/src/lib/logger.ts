/**
 * Thin logger wrapper for the frontend.
 *
 * In development, messages are forwarded to the browser console.
 * In production builds, only 'warn' and 'error' are emitted so that
 * debug chatter does not reach end-users.
 */

const isDev = import.meta.env.DEV;

export const logger = {
  debug: (...args: unknown[]): void => {
    if (isDev) console.debug(...args);
  },
  info: (...args: unknown[]): void => {
    if (isDev) console.info(...args);
  },
  warn: (...args: unknown[]): void => {
    console.warn(...args);
  },
  error: (...args: unknown[]): void => {
    console.error(...args);
  },
};
