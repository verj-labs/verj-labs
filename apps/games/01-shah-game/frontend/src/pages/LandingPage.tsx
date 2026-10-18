import { type FormEvent, useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { useSessionStore } from '@/store/sessionStore';
import { COPY } from '@/lib/copy';

const MIN_NAME = 2;
const MAX_NAME = 32;

export default function LandingPage() {
  const [displayName, setDisplayName] = useState('');
  const [error, setError] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const navigate = useNavigate();

  const { login, isLoading, isAuthenticated } = useSessionStore();

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  useEffect(() => {
    if (isAuthenticated) {
      void navigate('/lobby', { replace: true });
    }
  }, [isAuthenticated, navigate]);

  function validate(value: string): string | null {
    const trimmed = value.trim();
    if (trimmed.length < MIN_NAME) return `Name needs at least ${MIN_NAME} characters.`;
    if (trimmed.length > MAX_NAME) return `Name must be under ${MAX_NAME} characters.`;
    return null;
  }

  async function handleSubmit(e: FormEvent): Promise<void> {
    e.preventDefault();
    const validationError = validate(displayName);
    if (validationError) {
      setError(validationError);
      return;
    }
    setError(null);
    try {
      await login(displayName.trim());
      void navigate('/lobby', { replace: true });
    } catch {
      setError(COPY.genericError);
    }
  }

  return (
    <main className="min-h-screen bg-[var(--color-bg-0)] flex items-center justify-center p-4">
      <div className="w-full max-w-sm space-y-8">
        {/* Title */}
        <div className="text-center space-y-2">
          <h1 className="text-5xl font-bold tracking-tight" style={{ fontFamily: 'var(--font-heading)' }}>
            <span className="text-[var(--color-neon-lime)]">♠</span>{' '}
            <span className="text-[var(--color-text-primary)]">Shah</span>{' '}
            <span className="text-[var(--color-electric-yellow)]">Exchange</span>
          </h1>
          <p className="text-[var(--color-text-muted)] text-sm">
            {COPY.landingSubtitle}
          </p>
        </div>

        {/* Form */}
        <form
          onSubmit={(e) => void handleSubmit(e)}
          className="bg-[var(--color-surface)] border border-[var(--color-border)] rounded-lg p-6 space-y-4 shadow-xl"
          noValidate
        >
          <div className="space-y-1.5">
            <label
              htmlFor="displayName"
              className="block text-[var(--color-text-primary)] text-sm font-medium"
            >
              {COPY.displayNameLabel}
            </label>
            <input
              id="displayName"
              ref={inputRef}
              type="text"
              data-testid="display-name-input"
              value={displayName}
              onChange={(e) => {
                setDisplayName(e.target.value);
                if (error) setError(null);
              }}
              maxLength={MAX_NAME}
              placeholder={COPY.displayNamePlaceholder}
              disabled={isLoading}
              aria-invalid={error !== null}
              aria-describedby={error ? 'name-error' : undefined}
              className="w-full rounded-md border border-[var(--color-border)] bg-[var(--color-bg-1)] px-3 py-2 text-[var(--color-text-primary)] placeholder:text-[var(--color-text-muted)] focus:outline-none focus:ring-2 focus:ring-[var(--color-neon-lime)] disabled:opacity-50 transition"
            />
            {error && (
              <p id="name-error" role="alert" className="text-[var(--color-danger-red)] text-xs">
                {error}
              </p>
            )}
          </div>

          <Button
            type="submit"
            disabled={isLoading}
            data-testid="start-button"
            className="w-full"
            variant="cta"
            size="lg"
          >
            {isLoading ? (
              <span className="flex items-center gap-2">
                <LoadingSpinner size="sm" />
                {COPY.entering}
              </span>
            ) : (
              COPY.enterGame
            )}
          </Button>
        </form>
      </div>
    </main>
  );
}

