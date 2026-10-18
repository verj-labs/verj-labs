import { render, screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';

vi.mock('@/lib/config', () => ({
  config: { apiUrl: 'http://localhost:3000', socketUrl: 'http://localhost:3000' },
}));

vi.mock('@/services/auth.service', () => ({
  createSession: vi.fn(),
  deleteSession: vi.fn(),
  getMe: vi.fn(),
}));

import App from '../App';

describe('App smoke test', () => {
  it('renders without crashing', () => {
    render(<App />);
    // LandingPage is rendered at '/' and contains a <main> element
    expect(screen.getByRole('main')).toBeInTheDocument();
  });
});
