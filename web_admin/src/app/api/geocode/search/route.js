import { NextResponse } from "next/server";

const NOMINATIM = "https://nominatim.openstreetmap.org";
const HEADERS = {
  "User-Agent": "RutaSegura-WebAdmin/1.0 (school registration)",
  Accept: "application/json",
};

export async function GET(request) {
  const q = request.nextUrl.searchParams.get("q")?.trim();
  if (!q || q.length < 3) {
    return NextResponse.json({ results: [] });
  }

  try {
    const params = new URLSearchParams({
      format: "json",
      q,
      countrycodes: "ec",
      limit: "6",
      addressdetails: "1",
    });

    const res = await fetch(`${NOMINATIM}/search?${params}`, {
      headers: HEADERS,
      next: { revalidate: 3600 },
    });

    if (!res.ok) {
      return NextResponse.json({ error: "No se pudo buscar la direccion" }, { status: 502 });
    }

    const data = await res.json();
    const results = (Array.isArray(data) ? data : []).map((item) => ({
      lat: Number(item.lat),
      lng: Number(item.lon),
      label: item.display_name,
      name: item.name || item.display_name?.split(",")[0] || "",
    }));

    return NextResponse.json({ results });
  } catch {
    return NextResponse.json({ error: "Error de geocodificacion" }, { status: 500 });
  }
}