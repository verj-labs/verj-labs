import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { PlayingCard } from '@/components/ui/PlayingCard';

describe('PlayingCard', () => {
  it('renders face-up card with correct aria-label', () => {
    render(<PlayingCard rank="A" suit="spades" />);
    expect(screen.getByRole('button', { name: 'A of spades' })).toBeInTheDocument();
  });

  it('renders face-down card with generic aria-label', () => {
    render(<PlayingCard rank="K" suit="hearts" faceDown />);
    expect(screen.getByRole('button', { name: 'card face down' })).toBeInTheDocument();
  });

  it('calls onClick when clicked', async () => {
    const user = userEvent.setup();
    const onClick = vi.fn();
    render(<PlayingCard rank="10" suit="diamonds" onClick={onClick} />);
    await user.click(screen.getByRole('button'));
    expect(onClick).toHaveBeenCalledOnce();
  });

  it('does not call onClick when disabled', async () => {
    const user = userEvent.setup();
    const onClick = vi.fn();
    render(<PlayingCard rank="J" suit="clubs" onClick={onClick} disabled />);
    const btn = screen.getByRole('button');
    expect(btn).toBeDisabled();
    await user.click(btn);
    expect(onClick).not.toHaveBeenCalled();
  });

  it('marks selected card with aria-pressed', () => {
    render(<PlayingCard rank="Q" suit="hearts" selected />);
    expect(screen.getByRole('button')).toHaveAttribute('aria-pressed', 'true');
  });

  it('renders all three sizes without throwing', () => {
    const { rerender } = render(<PlayingCard rank="2" suit="clubs" size="sm" />);
    rerender(<PlayingCard rank="2" suit="clubs" size="md" />);
    rerender(<PlayingCard rank="2" suit="clubs" size="lg" />);
    expect(screen.getByRole('button')).toBeInTheDocument();
  });

  it('matches face-up snapshot', () => {
    const { container } = render(<PlayingCard rank="A" suit="hearts" size="md" />);
    expect(container.firstChild).toMatchSnapshot();
  });

  it('matches face-down snapshot', () => {
    const { container } = render(<PlayingCard rank="K" suit="spades" faceDown size="md" />);
    expect(container.firstChild).toMatchSnapshot();
  });
});
