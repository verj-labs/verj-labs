import axios, {
  type AxiosError,
  type AxiosInstance,
  type AxiosResponse,
  type InternalAxiosRequestConfig,
} from 'axios';
import { STORAGE_KEY_TOKEN } from '@/lib/constants';
import { config } from '@/lib/config';

/**
 * Returns the stored session token.
 * The real implementation lives in the sessionStore (EP-002).
 * This indirection keeps api.ts decoupled from the store implementation.
 */
function getStoredToken(): string | null {
  return localStorage.getItem(STORAGE_KEY_TOKEN);
}

/**
 * Clears session credentials from local storage.
 * Called on 401 responses so stale tokens don't persist.
 */
function clearStoredToken(): void {
  localStorage.removeItem(STORAGE_KEY_TOKEN);
}

const api: AxiosInstance = axios.create({
  baseURL: config.apiUrl,
  headers: {
    'Content-Type': 'application/json',
  },
});

// ─── Request interceptor — attach Bearer token ────────────────────────────────
api.interceptors.request.use(
  (reqConfig: InternalAxiosRequestConfig): InternalAxiosRequestConfig => {
    const token = getStoredToken();
    if (token) {
      reqConfig.headers.set('Authorization', `Bearer ${token}`);
    }
    return reqConfig;
  },
  (error: unknown) => Promise.reject(error),
);

// ─── Response interceptor — handle 401 ───────────────────────────────────────
api.interceptors.response.use(
  (response: AxiosResponse): AxiosResponse => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      clearStoredToken();
      // Navigate to the root / login page.
      // Using location.replace so the history stack is not polluted.
      window.location.replace('/');
    }
    return Promise.reject(error);
  },
);

export default api;
