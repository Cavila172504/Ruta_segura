import { NextResponse } from "next/server";

const NOMINATIM = "https://nominatim.openstreetmap.org";
const HEADERS = {
  "User-Agent": "RutaSegura-WebAdmin/1.0 (school registration)",
  Accept: "application/json",
};

export async function GET(request) {
  const lat = request.nextUrl.searchParams.get("lat");
  const lng = request.nextUrl.searchParams.get("lng");

  if (!lat || !lng) {
    return NextResponse.json({ error: "Coordenadas requeridas" }, { status: 400 });
  }

  try {
    const params = new URLSearchParams({
      format: "json",
      lat,
      lon: lng,
      zoom: "18",
      addressdetails: "1",
    });

    const res = await fetch(`${NOMINATIM}/reverse?${params}`, {
      headers: HEADERS,
      next: { revalidate: 3600 },
    });

    if (!res.ok) {
      return NextResponse.json({ error: "No se pudo obtener la direccion" }, { status: 502 });
    }

    const data = await res.json();
    return NextResponse.json({
      address: data.display_name || "",
    });
  } catch {
    return NextResponse.json({ error: "Error de geocodificacion" }, { status: 500 });
  }
}