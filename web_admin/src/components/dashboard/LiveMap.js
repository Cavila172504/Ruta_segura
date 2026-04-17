"use client";
import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap, Circle } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// ── Íconos SVG inline (siempre cargan, sin depender de CDN externos) ─────────

const createBusIcon = (isActive) => L.divIcon({
  html: `<div style="
    width:44px;height:44px;
    background:${isActive ? '#3b309e' : '#94a3b8'};
    border-radius:50%;
    display:flex;align-items:center;justify-content:center;
    border:3px solid white;
    box-shadow:0 2px 8px rgba(0,0,0,0.3);">
    <svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='white'>
      <path d='M4 16c0 .88.39 1.67 1 2.22V20c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h8v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1.78c.61-.55 1-1.34 1-2.22V6c0-3.5-3.58-4-8-4s-8 .5-8 4v10zm3.5 1c-.83 0-1.5-.67-1.5-1.5S6.67 14 7.5 14s1.5.67 1.5 1.5S8.33 17 7.5 17zm9 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zm1.5-6H6V6h12v5z'/>
    </svg>
  </div>`,
  className: '',
  iconSize: [44, 44],
  iconAnchor: [22, 22],
  popupAnchor: [0, -26],
});

const houseIcon = L.divIcon({
  html: `<div style="
    width:36px;height:36px;
    background:#5d5a85;
    border-radius:50%;
    display:flex;align-items:center;justify-content:center;
    border:2.5px solid white;
    box-shadow:0 2px 6px rgba(0,0,0,0.25);">
    <svg xmlns='http://www.w3.org/2000/svg' width='20' height='20' viewBox='0 0 24 24' fill='white'>
      <path d='M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z'/>
    </svg>
  </div>`,
  className: '',
  iconSize: [36, 36],
  iconAnchor: [18, 36],
  popupAnchor: [0, -36],
});

const schoolIcon = L.divIcon({
  html: `<div style="
    width:52px;height:52px;
    background:#f59e0b;
    border-radius:50%;
    display:flex;align-items:center;justify-content:center;
    border:3px solid white;
    box-shadow:0 3px 10px rgba(0,0,0,0.3);">
    <svg xmlns='http://www.w3.org/2000/svg' width='28' height='28' viewBox='0 0 24 24' fill='white'>
      <path d='M5 13.18v4L12 21l7-3.82v-4L12 17l-7-3.82zM12 3 1 9l11 6 9-4.91V17h2V9L12 3z'/>
    </svg>
  </div>`,
  className: '',
  iconSize: [52, 52],
  iconAnchor: [26, 26],
  popupAnchor: [0, -30],
});

// ── Helper: auto-centra el mapa cuando llegan los primeros buses ─────────────
function AutoCenter({ buses, defaultCenter }) {
  const map = useMap();
  useEffect(() => {
    const activeBus = buses.find(b => b.lat && b.lng);
    if (activeBus) {
      map.setView([activeBus.lat, activeBus.lng], 15);
    } else {
      map.setView(defaultCenter, 14);
    }
  }, [buses, defaultCenter, map]);
  return null;
}

// ── Componente principal ─────────────────────────────────────────────────────
export default function LiveMap({ buses, students }) {
  const [isMounted, setIsMounted] = useState(false);

  // Centro fijo: Colegio CADE – Km 14.5 vía Quevedo, Santo Domingo
  const cadeCenter = [-0.3485881, -79.2477156];

  useEffect(() => { 
    const timer = setTimeout(() => setIsMounted(true), 0);
    return () => clearTimeout(timer);
  }, []);

  if (!isMounted) {
    return (
      <div className="w-full h-[520px] bg-slate-100 animate-pulse rounded-2xl flex items-center justify-center text-slate-400 font-black uppercase tracking-widest italic">
        Iniciando Monitorización...
      </div>
    );
  }

  const formatTime = (ts) => {
    if (!ts) return '—';
    const d = ts.toDate ? ts.toDate() : new Date(ts);
    return d.toLocaleTimeString('es-EC', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  };

  return (
    <div className="w-full h-[520px] rounded-2xl overflow-hidden border-2 border-slate-200 shadow-lg relative">
      <MapContainer
        center={cadeCenter}
        zoom={14}
        style={{ height: '100%', width: '100%' }}
        scrollWheelZoom={true}
        zoomControl={true}
      >
        {/* Tiles estilo Google Maps (igual que la app del conductor) */}
        <TileLayer
          attribution='&copy; Google Maps Style'
          url="https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}"
        />

        <AutoCenter buses={buses} defaultCenter={cadeCenter} />

        {/* ── Marcador del Colegio CADE ── */}
        <Marker position={cadeCenter} icon={schoolIcon}>
          <Popup>
            <div className="text-center p-2 min-w-[160px]">
              <p className="font-extrabold text-primary text-base">COLEGIO CADE</p>
              <p className="text-xs text-slate-500 italic mt-1">Km 14½ vía Quevedo</p>
              <span className="bg-primary/10 text-primary text-xs px-2 py-0.5 rounded-full font-black mt-2 inline-block">
                CENTRO DE OPERACIONES
              </span>
            </div>
          </Popup>
        </Marker>

        {/* ── Paradas de Estudiantes ── */}
        {students.map((student) => {
          const lat = student.stopLat ?? student.lat;
          const lng = student.stopLng ?? student.lng;
          if (!lat || !lng) return null;
          return (
            <Marker key={student.id} position={[lat, lng]} icon={houseIcon}>
              <Popup>
                <div className="p-2 min-w-[160px]">
                  <p className="font-black text-on-surface text-sm leading-none">
                    {student.studentName || student.name || 'Estudiante'}
                  </p>
                  <p className="text-xs text-slate-500 font-bold mt-0.5 uppercase">
                    {student.grade || student.curso || '—'}
                  </p>
                  <div className="mt-2 bg-slate-50 rounded-lg p-2 text-xs text-slate-600">
                    <span className="font-black text-primary">Parada registrada</span>
                    <br />
                    {lat.toFixed(5)}, {lng.toFixed(5)}
                  </div>
                </div>
              </Popup>
            </Marker>
          );
        })}

        {/* ── Conductores (live_tracking) ── */}
        {buses.map((bus) => {
          const lat = bus.lat ?? bus.latitude;
          const lng = bus.lng ?? bus.longitude;
          if (!lat || !lng) return null;
          const isActive = bus.status === 'on_route';
          return (
            <React.Fragment key={bus.id}>
              {isActive && (
                <Circle
                  center={[lat, lng]}
                  radius={80}
                  pathOptions={{ color: '#3b309e', fillColor: '#3b309e', fillOpacity: 0.08, weight: 1 }}
                />
              )}
              <Marker position={[lat, lng]} icon={createBusIcon(isActive)}>
                <Popup>
                  <div className="p-2 min-w-[180px]">
                    <div className="flex items-center gap-2 mb-2">
                      <div className={`w-2.5 h-2.5 rounded-full ${isActive ? 'bg-emerald-500 animate-pulse' : 'bg-slate-300'}`}></div>
                      <p className={`text-xs font-black uppercase tracking-widest ${isActive ? 'text-emerald-600' : 'text-slate-400'}`}>
                        {isActive ? 'EN RUTA' : 'DETENIDO'}
                      </p>
                    </div>
                    <p className="font-extrabold text-primary text-sm">{bus.driverName || 'Conductor'}</p>
                    <div className="mt-2 space-y-1 text-xs text-slate-500">
                      {bus.speed != null && (
                        <p><span className="font-bold">Velocidad:</span> {parseFloat(bus.speed).toFixed(1)} km/h</p>
                      )}
                      {bus.altitude != null && (
                        <p><span className="font-bold">Altitud:</span> {parseFloat(bus.altitude).toFixed(0)} m</p>
                      )}
                      <p><span className="font-bold">Actualizado:</span> {formatTime(bus.updatedAt || bus.timestamp)}</p>
                    </div>
                  </div>
                </Popup>
              </Marker>
            </React.Fragment>
          );
        })}
      </MapContainer>

      {/* Badge de total en el mapa */}
      <div className="absolute bottom-4 left-4 z-[1000] bg-white/90 backdrop-blur-md p-3 rounded-xl shadow-md border border-white flex items-center gap-3">
        <div className="flex items-center gap-1.5">
          <div className="w-2.5 h-2.5 bg-primary rounded-full animate-pulse"></div>
          <span className="text-xs font-black text-primary">{buses.filter(b => b.lat || b.latitude).length} Bus(es)</span>
        </div>
        <div className="w-px h-4 bg-slate-200"></div>
        <div className="flex items-center gap-1.5">
          <div className="w-2.5 h-2.5 bg-secondary rounded-full"></div>
          <span className="text-xs font-black text-secondary">{students.filter(s => (s.stopLat || s.lat) && (s.stopLng || s.lng)).length} Parada(s)</span>
        </div>
      </div>
    </div>
  );
}
