"use client";
import React, { useEffect, useState } from "react";
import { MapContainer, TileLayer, Marker, useMapEvents } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

const DEFAULT_CENTER = [-0.3485881, -79.2477156];

const pinIcon = L.divIcon({
  html: `<div style="width:32px;height:32px;background:#3b309e;border-radius:50% 50% 50% 0;transform:rotate(-45deg);border:3px solid white;box-shadow:0 2px 8px rgba(0,0,0,0.3);"></div>`,
  className: "",
  iconSize: [32, 32],
  iconAnchor: [16, 32],
});

function MapClickHandler({ onChange }) {
  useMapEvents({
    click(e) {
      onChange(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

export default function CompanyLocationPicker({ lat, lng, onChange, schoolName }) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    const t = setTimeout(() => setMounted(true), 0);
    return () => clearTimeout(t);
  }, []);

  const position = [
    lat != null && !Number.isNaN(Number(lat)) ? Number(lat) : DEFAULT_CENTER[0],
    lng != null && !Number.isNaN(Number(lng)) ? Number(lng) : DEFAULT_CENTER[1],
  ];

  if (!mounted) {
    return (
      <div className="w-full h-48 bg-slate-100 animate-pulse rounded-xl flex items-center justify-center text-xs font-bold text-slate-400">
        Cargando mapa...
      </div>
    );
  }

  return (
    <div className="space-y-2">
      <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest">
        Ubicacion del colegio (clic en el mapa)
      </p>
      <div className="w-full h-52 rounded-xl overflow-hidden border border-slate-200">
        <MapContainer center={position} zoom={15} style={{ height: "100%", width: "100%" }} scrollWheelZoom>
          <TileLayer url="https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}" />
          <MapClickHandler onChange={onChange} />
          {lat != null && lng != null && <Marker position={position} icon={pinIcon} />}
        </MapContainer>
      </div>
      <p className="text-[10px] text-slate-500 font-medium">
        {lat != null && lng != null
          ? `${Number(lat).toFixed(5)}, ${Number(lng).toFixed(5)}${schoolName ? ` - ${schoolName}` : ""}`
          : "Selecciona el punto del colegio en el mapa"}
      </p>
    </div>
  );
}
