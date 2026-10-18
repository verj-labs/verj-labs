import { useEffect } from 'react';
import { RouterProvider } from 'react-router-dom';
import { Toaster } from '@/components/ui/sonner';
import { TooltipProvider } from '@/components/ui/tooltip';
import { router } from '@/router';
import { useSessionStore } from '@/store/sessionStore';
import './index.css';

export default function App() {
  const restoreSession = useSessionStore((s) => s.restoreSession);

  // Restore persisted session once on app mount before rendering routes
  useEffect(() => {
    void restoreSession();
  }, [restoreSession]);

  return (
    <TooltipProvider>
      <RouterProvider router={router} />
      <Toaster richColors position="top-right" />
    </TooltipProvider>
  );
}
