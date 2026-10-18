import { Navigate, Outlet } from 'react-router-dom';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { useSessionStore } from '@/store/sessionStore';

/**
 * Wraps protected routes. Shows a spinner while session is being restored,
 * redirects to "/" if the user is not authenticated, otherwise renders
 * child routes via <Outlet />.
 */
export default function ProtectedRoute() {
  const { isAuthenticated, isLoading } = useSessionStore();

  if (isLoading) {
    return (
      <div
        className="min-h-screen bg-[var(--color-bg-0)] flex items-center justify-center"
        aria-live="polite"
      >
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/" replace />;
  }

  return <Outlet />;
}
