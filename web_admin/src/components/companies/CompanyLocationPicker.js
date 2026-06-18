"use client";
import React, { useEffect, useState, useCallback, useRef } from "react";
import Map, { Marker, NavigationControl } from "react-map-gl/maplibre";
import { MAP_VECTOR_STREETS_STYLE, DEFAULT_MAP_CENTER } from "@/lib/polyline";

function normalizeCoordInput(text) {
  return text.trim().replace(/[\u2212\u2013\u2014]/g, "-");
}

function validateCoords(lat, lng) {
  if (Number.isNaN(lat) || Number.isNaN(lng)) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return { lat, lng };
}

/** Acepta: "-0.28, -78.46" | "-0.28 -78.46" | "lat: -0.28, lng: -78.46" */
function parseCoordinates(text) {
  const q = normalizeCoordInput(text);
  if (!q) return null;

  const labeled = q.match(
    /lat(?:itud)?[:\s=]+(-?\d+(?:\.\d+)?)[\s,;]+l(?:ng|on|ongitud)?[:\s=]+(-?\d+(?:\.\d+)?)/i
  );
  if (labeled) return validateCoords(Number(labeled[1]), Number(labeled[2]));

  const pair = q.match(/^(-?\d+(?:\.\d+)?)[\s,;]+(-?\d+(?:\.\d+)?)$/);
  if (pair) return validateCoords(Number(pair[1]), Number(pair[2]));

  return null;
}

function LocationPin() {
  return (
    <div
      style={{
        width: 32,
        height: 32,
        background: "#3b309e",
        borderRadius: "50% 50% 50% 0",
        transform: "rotate(-45deg)",
        border: "3px solid white",
        boxShadow: "0 2px 8px rgba(0,0,0,0.3)",
        cursor: "grab",
      }}
    />
  );
}

export default function CompanyLocationPicker({
  lat,
  lng,
  onChange,
  schoolName,
  address = "",
  onAddressChange,
}) {
  const [mounted, setMounted] = useState(false);
  const [query, setQuery] = useState("");
  const [results, setResults] = useState([]);
  const [searching, setSearching] = useState(false);
  const [showResults, setShowResults] = useState(false);
  const searchRef = useRef(null);
  const mapRef = useRef(null);

  useEffect(() => {
    const t = setTimeout(() => setMounted(true), 0);
    return () => clearTimeout(t);
  }, []);

  useEffect(() => {
    if (!showResults) return;
    const handleClick = (e) => {
      if (searchRef.current && !searchRef.current.contains(e.target)) {
        setShowResults(false);
      }
    };
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, [showResults]);

  const hasPin = lat != null && lng != null;

  const centerLat = hasPin ? Number(lat) : DEFAULT_MAP_CENTER[0];
  const centerLng = hasPin ? Number(lng) : DEFAULT_MAP_CENTER[1];

  const reverseGeocode = useCallback(
    async (newLat, newLng) => {
      if (!onAddressChange) return;
      try {
        const res = await fetch(`/api/geocode/reverse?lat=${newLat}&lng=${newLng}`);
        const data = await res.json();
        if (data.address) onAddressChange(data.address);
      } catch {
        /* ignore */
      }
    },
    [onAddressChange]
  );

  const handleLocationChange = useCallback(
    (newLat, newLng) => {
      onChange(newLat, newLng);
      reverseGeocode(newLat, newLng);
    },
    [onChange, reverseGeocode]
  );

  const flyTo = useCallback((newLat, newLng, zoom = 16) => {
    const map = mapRef.current?.getMap?.();
    if (map) {
      map.flyTo({ center: [newLng, newLat], zoom, duration: 800 });
    }
  }, []);

  useEffect(() => {
    if (!mounted || !hasPin) return;
    flyTo(Number(lat), Number(lng), 16);
  }, [mounted, hasPin, lat, lng, flyTo]);

  useEffect(() => {
    if (!mounted) return;
    const map = mapRef.current?.getMap?.();
    if (!map) return;
    const fix = () => map.resize();
    const t = setTimeout(fix, 100);
    return () => clearTimeout(t);
  }, [mounted]);

  const runSearch = useCallback(
    async (searchText) => {
      const q = normalizeCoordInput(searchText);
      if (q.length < 3) return;

      const coords = parseCoordinates(q);
      if (coords) {
        setSearching(false);
        setShowResults(false);
        setResults([]);
        handleLocationChange(coords.lat, coords.lng);
        setQuery(`${coords.lat.toFixed(5)}, ${coords.lng.toFixed(5)}`);
        flyTo(coords.lat, coords.lng, 16);
        return;
      }

      setSearching(true);
      setShowResults(true);
      try {
        const res = await fetch(`/api/geocode/search?q=${encodeURIComponent(q)}`);
        const data = await res.json();
        setResults(data.results || []);
      } catch {
        setResults([]);
      } finally {
        setSearching(false);
      }
    },
    [handleLocationChange, flyTo]
  );

  const searchBySchoolName = () => {
    const parts = [schoolName, "colegio", "Ecuador"].filter(Boolean);
    const q = parts.join(", ");
    setQuery(q);
    runSearch(q);
  };

  const selectResult = (item) => {
    handleLocationChange(item.lat, item.lng);
    if (onAddressChange && item.label) onAddressChange(item.label);
    setQuery(item.label);
    setShowResults(false);
    flyTo(item.lat, item.lng, 16);
  };

  const handleSearchSubmit = (e) => {
    e.preventDefault();
    e.stopPropagation();
    runSearch(query);
  };

  const handleSearchKeyDown = (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      e.stopPropagation();
      runSearch(query);
    }
  };

  const handleMapClick = (e) => {
    const { lng: newLng, lat: newLat } = e.lngLat;
    handleLocationChange(newLat, newLng);
  };

  const parsedCoords = parseCoordinates(query);
  const canSearch = !!parsedCoords || query.trim().length >= 3;

  if (!mounted) {
    return (
      <div className="w-full h-40 bg-slate-100 animate-pulse rounded-xl flex items-center justify-center text-xs font-medium text-slate-400">
        Cargando mapa...
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between gap-2">
        <label className="text-xs font-semibold text-slate-600">Ubicacion del colegio</label>
        {hasPin ? (
          <span className="inline-flex items-center gap-1 text-[10px] font-semibold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full">
            <span className="material-symbols-outlined text-xs">check_circle</span>
            Ubicacion marcada
          </span>
        ) : (
          <span className="inline-flex items-center gap-1 text-[10px] font-semibold text-amber-700 bg-amber-50 px-2 py-0.5 rounded-full">
            <span className="material-symbols-outlined text-xs">warning</span>
            Pendiente
          </span>
        )}
      </div>

      <div ref={searchRef} className="relative">
        <div className="flex gap-2">
          <div className="relative flex-1">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-lg pointer-events-none">
              search
            </span>
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={handleSearchKeyDown}
              onFocus={() => results.length > 0 && setShowResults(true)}
              placeholder="Direccion, nombre del colegio o coordenadas (lat, lng)"
              className="w-full pl-10 pr-3 py-2.5 bg-white border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-primary/20 outline-none"
            />
          </div>
          <button
            type="button"
            onClick={handleSearchSubmit}
            disabled={searching || !canSearch}
            className="px-4 py-2.5 bg-primary text-white rounded-xl text-xs font-semibold hover:bg-primary/90 disabled:opacity-50 transition-colors shrink-0"
          >
            {searching ? "..." : "Buscar"}
          </button>
        </div>

        {schoolName && (
          <button
            type="button"
            onClick={searchBySchoolName}
            className="mt-2 text-xs font-semibold text-primary hover:underline flex items-center gap-1"
          >
            <span className="material-symbols-outlined text-sm">school</span>
            Buscar &quot;{schoolName}&quot; en el mapa
          </button>
        )}

        {showResults && results.length > 0 && (
          <ul className="absolute z-20 left-0 right-0 mt-1 bg-white border border-slate-200 rounded-xl shadow-lg max-h-48 overflow-y-auto">
            {results.map((item, i) => (
              <li key={`${item.lat}-${item.lng}-${i}`}>
                <button
                  type="button"
                  onClick={() => selectResult(item)}
                  className="w-full text-left px-3 py-2.5 text-sm hover:bg-violet-50 border-b border-slate-50 last:border-0 flex items-start gap-2"
                >
                  <span className="material-symbols-outlined text-primary text-base mt-0.5 shrink-0">location_on</span>
                  <span className="line-clamp-2">{item.label}</span>
                </button>
              </li>
            ))}
          </ul>
        )}

        {showResults && !searching && results.length === 0 && query.trim().length >= 3 && !parsedCoords && (
          <p className="absolute z-20 left-0 right-0 mt-1 px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs text-slate-500 shadow-lg">
            No se encontraron resultados. Prueba con direccion, nombre del colegio o coordenadas (ej. -0.28304, -78.46309).
          </p>
        )}
      </div>

      <div className="w-full h-44 rounded-xl overflow-hidden border border-slate-200 relative z-0 isolate">
        <Map
          ref={mapRef}
          mapStyle={MAP_VECTOR_STREETS_STYLE}
          initialViewState={{
            longitude: centerLng,
            latitude: centerLat,
            zoom: hasPin ? 16 : 7,
          }}
          style={{ width: "100%", height: "100%" }}
          scrollZoom={false}
          dragPan
          doubleClickZoom={false}
          touchZoomRotate={false}
          onClick={handleMapClick}
        >
          <NavigationControl position="top-right" showCompass={false} visualizePitch={false} />
          {hasPin && (
            <Marker
              longitude={Number(lng)}
              latitude={Number(lat)}
              anchor="bottom"
              draggable
              onDragEnd={(e) => {
                const { lng: newLng, lat: newLat } = e.lngLat;
                handleLocationChange(newLat, newLng);
              }}
            >
              <LocationPin />
            </Marker>
          )}
        </Map>
      </div>

      <p className="text-xs text-slate-500 leading-relaxed">
        {hasPin
          ? "Arrastra el pin morado para ajustar la posicion exacta del colegio."
          : "Busca por direccion, nombre o pega coordenadas (lat, lng). Tambien puedes hacer clic en el mapa."}
      </p>

      {hasPin && (
        <p className="text-[11px] text-slate-400 font-mono">
          {Number(lat).toFixed(5)}, {Number(lng).toFixed(5)}
        </p>
      )}

      {address && (
        <div className="p-2.5 bg-slate-50 rounded-lg border border-slate-100">
          <p className="text-[10px] font-semibold text-slate-400 uppercase mb-0.5">Direccion detectada</p>
          <p className="text-xs text-slate-700 leading-snug">{address}</p>
        </div>
      )}
    </div>
  );
}
