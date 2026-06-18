export function decodePolyline(encoded) {
  if (!encoded || typeof encoded !== "string") return [];

  const points = [];
  let index = 0;
  let lat = 0;
  let lng = 0;

  while (index < encoded.length) {
    let shift = 0;
    let result = 0;
    let byte;

    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    const deltaLat = (result & 1) ? ~(result >> 1) : (result >> 1);
    lat += deltaLat;

    shift = 0;
    result = 0;

    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    const deltaLng = (result & 1) ? ~(result >> 1) : (result >> 1);
    lng += deltaLng;

    points.push([lat / 1e5, lng / 1e5]);
  }

  return points;
}

export const DEFAULT_MAP_CENTER = [-0.3485881, -79.2477156];

export function parseLatLng(value) {
  if (value == null || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const n = Number(value.trim().replace(",", "."));
    return Number.isFinite(n) ? n : null;
  }
  if (typeof value === "object") {
    if (typeof value.latitude === "number") return value.latitude;
    if (typeof value.lat === "number") return value.lat;
    if (typeof value.longitude === "number") return value.longitude;
    if (typeof value.lng === "number") return value.lng;
  }
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

export function resolveMapCenter(lat, lng, fallback = DEFAULT_MAP_CENTER) {
  const la = parseLatLng(lat);
  const ln = parseLatLng(lng);
  if (la != null && ln != null && la >= -90 && la <= 90 && ln >= -180 && ln <= 180) {
    return [la, ln];
  }
  return fallback;
}

/** Estilo vectorial (OpenFreeMap) — nitidez en zoom, menos datos que raster */
export const MAP_VECTOR_STREETS_STYLE =
  process.env.NEXT_PUBLIC_MAP_STYLE_STREETS || "https://tiles.openfreemap.org/styles/liberty";

/** Satélite con etiquetas (raster dentro de MapLibre) */
export const MAP_VECTOR_SATELLITE_STYLE = {
  version: 8,
  sources: {
    esri: {
      type: "raster",
      tiles: [
        "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
      ],
      tileSize: 256,
      attribution: "© Esri",
      maxzoom: 19,
    },
    labels: {
      type: "raster",
      tiles: [
        "https://a.basemaps.cartocdn.com/rastertiles/voyager_only_labels/{z}/{x}/{y}@2x.png",
        "https://b.basemaps.cartocdn.com/rastertiles/voyager_only_labels/{z}/{x}/{y}@2x.png",
        "https://c.basemaps.cartocdn.com/rastertiles/voyager_only_labels/{z}/{x}/{y}@2x.png",
        "https://d.basemaps.cartocdn.com/rastertiles/voyager_only_labels/{z}/{x}/{y}@2x.png",
      ],
      tileSize: 256,
      maxzoom: 20,
    },
  },
  layers: [
    { id: "esri", type: "raster", source: "esri" },
    { id: "labels", type: "raster", source: "labels", paint: { "raster-opacity": 0.85 } },
  ],
};

/** Capas raster legacy (Leaflet) — conservadas por compatibilidad */
export const MAP_TILE_LAYERS = {
  streets: {
    url: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png",
    attribution: "&copy; OpenStreetMap &copy; CARTO",
    subdomains: "abcd",
    maxZoom: 20,
  },
  satellite: {
    url: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
    attribution: "&copy; Esri",
    maxZoom: 19,
  },
  satelliteLabels: {
    url: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager_only_labels/{z}/{x}/{y}{r}.png",
    attribution: "",
    subdomains: "abcd",
    maxZoom: 20,
  },
};
