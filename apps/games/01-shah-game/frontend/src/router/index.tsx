import { createBrowserRouter, Navigate } from 'react-router-dom';
import LandingPage from '@/pages/LandingPage';
import LobbyPage from '@/pages/LobbyPage';
import RoomPage from '@/pages/RoomPage';
import GamePage from '@/pages/GamePage';
import HistoryPage from '@/pages/HistoryPage';
import ResultsPage from '@/pages/ResultsPage';
import ProtectedRoute from '@/router/ProtectedRoute';

export const router = createBrowserRouter([
  {
    path: '/',
    element: <LandingPage />,
  },
  {
    // Protected routes — must be authenticated
    element: <ProtectedRoute />,
    children: [
      { path: 'lobby', element: <LobbyPage /> },
      { path: 'history', element: <HistoryPage /> },
      { path: 'room/:code', element: <RoomPage /> },
      { path: 'game/:matchId', element: <GamePage /> },
      { path: 'results/:matchId', element: <ResultsPage /> },
    ],
  },
  {
    // Catch-all fallback
    path: '*',
    element: <Navigate to="/" replace />,
  },
]);
