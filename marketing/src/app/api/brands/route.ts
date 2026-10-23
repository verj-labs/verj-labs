import { NextResponse } from "next/server";
import { listBrands } from "@/pipeline/brand";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const brands = await listBrands();
    return NextResponse.json({ brands });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Could not read brands.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
