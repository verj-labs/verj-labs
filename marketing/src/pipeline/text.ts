export function words(value: string): number {
  return value.trim().split(/\s+/).filter(Boolean).length;
}

export function findBanned(text: string, phrases: string[]): string[] {
  const hay = text.toLowerCase();
  return phrases.filter((phrase) => phrase.trim() && hay.includes(phrase.toLowerCase()));
}

export function voiceScript(lines: string[]): string {
  return lines.map((line) => line.trim()).filter(Boolean).join(" ");
}

export function captionText(lines: string[], cta: string): string {
  return [...lines.map((line) => line.trim()).filter(Boolean), "", cta.trim()].join("\n");
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}
