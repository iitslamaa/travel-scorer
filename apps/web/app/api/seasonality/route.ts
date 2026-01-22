import { NextResponse } from "next/server";
import { computeSeasonality } from "@/lib/seasonality";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const monthStr = searchParams.get("month");
  const month = Number(monthStr);

  if (!Number.isFinite(month) || month < 1 || month > 12) {
    return NextResponse.json(
      { error: "Invalid month. Provide month=1..12", got: monthStr },
      { status: 400 }
    );
  }

  const data = computeSeasonality(month);
  return NextResponse.json(data);
}