/**
 * Type-safe access to Vite environment variables.
 * Throws at module load time if required variables are missing,
 * so misconfiguration is caught immediately.
 */

function requireEnv(key: string): string {
  const value = import.meta.env[key] as string | undefined;
  if (!value) {
    throw new Error(
      `Missing required environment variable: ${key}. Check your .env file against .env.example.`,
    );
  }
  return value;
}

export const config = {
  apiUrl: requireEnv('VITE_API_URL'),
  socketUrl: requireEnv('VITE_SOCKET_URL'),
} as const;

export type AppConfig = typeof config;
