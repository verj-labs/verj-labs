import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { brandSchema, type Brand } from "./types";

const BRAND_ID = /^[a-z0-9][a-z0-9-]*$/;

export function brandsDir(): string {
  return path.join(process.cwd(), "brands");
}

export function isBrandId(id: string): boolean {
  return BRAND_ID.test(id) && !id.startsWith("_");
}

export async function loadBrand(id: string): Promise<Brand> {
  if (!isBrandId(id)) throw new Error(`Unknown brand "${id}".`);
  const file = path.join(brandsDir(), id, "brand.json");
  let raw: unknown;
  try {
    raw = JSON.parse(await readFile(file, "utf8"));
  } catch {
    throw new Error(`No brand kit at brands/${id}/brand.json.`);
  }
  const parsed = brandSchema.safeParse(raw);
  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    throw new Error(`brands/${id}/brand.json is invalid: ${issue?.path.join(".")} ${issue?.message}`);
  }
  if (parsed.data.id !== id) {
    throw new Error(`Brand id "${parsed.data.id}" does not match folder "${id}".`);
  }
  return parsed.data;
}

export function brandAsset(brand: Brand, file: string): string {
  if (file.includes("..") || path.isAbsolute(file)) {
    throw new Error(`Brand asset path is not allowed: ${file}`);
  }
  return path.join(brandsDir(), brand.id, "assets", file);
}

export async function listBrands(): Promise<{ id: string; name: string }[]> {
  const entries = await readdir(brandsDir(), { withFileTypes: true });
  const brands: { id: string; name: string }[] = [];
  for (const entry of entries) {
    if (!entry.isDirectory() || !isBrandId(entry.name)) continue;
    const brand = await loadBrand(entry.name);
    brands.push({ id: brand.id, name: brand.name });
  }
  brands.sort((a, b) => a.name.localeCompare(b.name));
  return brands;
}
