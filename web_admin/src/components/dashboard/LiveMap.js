"use client";
import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap, Circle, Polyline, ZoomControl } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { decodePolyline } from '@/lib/polyline';

// ── Íconos SVG inline (siempre cargan, sin depender de CDN externos) ─────────

const createBusIcon = (isActive, routeLabel = '') => L.divIcon({
  html: `<div style="display:flex;flex-direction:column;align-items:center;">
    ${routeLabel ? `<span style="font-size:9px;font-weight:800;color:#1e3a8a;background:white;padding:1px 6px;border-radius:8px;margin-bottom:2px;box-shadow:0 1px 4px rgba(0,0,0,.15);">${routeLabel}</span>` : ''}
    <div style="
    width:44px;height:44px;
    background:${isActive ? '#4361ee' : '#94a3b8'};
    border-radius:50%;
    display:flex;align-items:center;justify-content:center;
    border:3px solid white;
    box-shadow:0 2px 8px rgba(0,0,0,0.3);">
    <svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='white'>
      <path d='M4 16c0 .88.39 1.67 1 2.22V20c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h8v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1.78c.61-.55 1-1.34 1-2.22V6c0-3.5-3.58-4-8-4s-8 .5-8 4v10zm3.5 1c-.83 0-1.5-.67-1.5-1.5S6.67 14 7.5 14s1.5.67 1.5 1.5S8.33 17 7.5 17zm9 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zm1.5-6H6V6h12v5z'/>
    </svg>
  </div></div>`,
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
const FALLBACK_CENTER = [-0.3485881, -79.2477156];

export default function LiveMap({ buses, students, schoolCenter, schoolName, schoolAddress, routeByDriver = {}, showStudents = true, mapHeight = 'min(68vh, 620px)' }) {
  const [isMounted, setIsMounted] = useState(false);
  const [mapType, setMapType] = useState('road');

  const mapCenter = schoolCenter?.lat != null && schoolCenter?.lng != null
    ? [schoolCenter.lat, schoolCenter.lng]
    : FALLBACK_CENTER;

  useEffect(() => { 
    const timer = setTimeout(() => setIsMounted(true), 0);
    return () => clearTimeout(timer);
  }, []);

  if (!isMounted) {
    return (
      <div className="w-full bg-slate-100 animate-pulse rounded-2xl flex items-center justify-center text-slate-400 font-black uppercase tracking-widest italic" style={{ height: mapHeight }}>
        Iniciando Monitorización...
      </div>
    );
  }

  const tileUrl = mapType === 'satellite'
    ? 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}'
    : 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';

  const visibleStudents = showStudents ? students : [];

  const formatTime = (ts) => {
    if (!ts) return '—';
    const d = ts.toDate ? ts.toDate() : new Date(ts);
    return d.toLocaleTimeString('es-EC', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  };

  return (
    <div className="w-full rounded-2xl overflow-hidden border border-slate-200 shadow-lg relative bg-slate-100" style={{ height: mapHeight }}>
      <div className="absolute top-4 left-4 z-[1000] flex flex-col gap-2">
        <div className="bg-white rounded-xl shadow-md border border-slate-100 overflow-hidden flex flex-col">
          <button type="button" onClick={() => setMapType('road')} className={`px-3 py-2 text-[10px] font-black uppercase ${mapType === 'road' ? 'bg-[#4361ee] text-white' : 'text-slate-600 hover:bg-slate-50'}`}>Mapa</button>
          <button type="button" onClick={() => setMapType('satellite')} className={`px-3 py-2 text-[10px] font-black uppercase border-t border-slate-100 ${mapType === 'satellite' ? 'bg-[#4361ee] text-white' : 'text-slate-600 hover:bg-slate-50'}`}>Satélite</button>
        </div>
      </div>

      <MapContainer
        center={mapCenter}
        zoom={14}
        style={{ height: '100%', width: '100%' }}
        scrollWheelZoom={true}
        zoomControl={false}
      >
        <TileLayer
          key={mapType}
          attribution='&copy; Google'
          url={tileUrl}
        />

        <AutoCenter buses={buses} defaultCenter={mapCenter} />
        <ZoomControl position="topleft" />

        {/* ── Marcador del colegio ── */}
        <Marker position={mapCenter} icon={schoolIcon}>
          <Popup>
            <div className="text-center p-2 min-w-[160px]">
              <p className="font-extrabold text-primary text-base">{schoolName || 'COLEGIO'}</p>
              <p className="text-xs text-slate-500 italic mt-1">{schoolAddress || 'Sede educativa'}</p>
              <span className="bg-primary/10 text-primary text-xs px-2 py-0.5 rounded-full font-black mt-2 inline-block">
                CENTRO DE OPERACIONES
              </span>
            </div>
          </Popup>
        </Marker>

        {/* ── Paradas de Estudiantes ── */}
        {visibleStudents.map((student) => {
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

        {/* ── Rutas activas (polyline del conductor) ── */}
        {buses.map((bus) => {
          const routeJson = bus.fullRouteJson;
          if (!routeJson || bus.status !== 'on_route') return null;
          const points = decodePolyline(routeJson);
          if (points.length < 2) return null;
          return (
            <Polyline
              key={`route-${bus.id}`}
              positions={points}
              pathOptions={{ color: '#4361ee', weight: 5, opacity: 0.85 }}
            />
          );
        })}

        {/* ── Conductores (live_tracking) ── */}
        {buses.map((bus) => {
          const lat = bus.lat ?? bus.latitude;
          const lng = bus.lng ?? bus.longitude;
          if (!lat || !lng) return null;
          const isActive = bus.status === 'on_route';
          const routeInfo = routeByDriver[bus.driverId || bus.id] || {};
          const routeLabel = routeInfo.name ? `R-${String(routeInfo.name).slice(0, 8)}` : '';
          const studentCount = routeInfo.studentCount ?? 0;
          return (
            <React.Fragment key={bus.id}>
              {isActive && (
                <Circle
                  center={[lat, lng]}
                  radius={80}
                  pathOptions={{ color: '#4361ee', fillColor: '#4361ee', fillOpacity: 0.08, weight: 1 }}
                />
              )}
              <Marker position={[lat, lng]} icon={createBusIcon(isActive, routeLabel)}>
                <Popup>
                  <div className="p-3 min-w-[200px]">
                    <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">
                      {routeInfo.name ? `Ruta ${routeInfo.name}` : 'Unidad activa'}
                    </p>
                    <p className="font-extrabold text-[#4361ee] text-sm">{bus.driverName || 'Conductor'}</p>
                    <div className="mt-2 space-y-1 text-xs text-slate-600">
                      <p><span className="font-bold">Estudiantes:</span> {studentCount}</p>
                      {bus.speed != null && (
                        <p><span className="font-bold">Velocidad:</span> {parseFloat(bus.speed).toFixed(0)} km/h</p>
                      )}
                      <p><span className="font-bold">Actualizado:</span> {formatTime(bus.lastUpdated || bus.updatedAt || bus.timestamp)}</p>
                    </div>
                    <span className={`inline-block mt-2 px-2 py-0.5 rounded-full text-[10px] font-black uppercase ${isActive ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-500'}`}>
                      {isActive ? 'A tiempo' : 'Detenido'}
                    </span>
                  </div>
                </Popup>
              </Marker>
            </React.Fragment>
          );
        })}
      </MapContainer>

      <div className="absolute top-4 right-4 z-[1000] bg-white/90 backdrop-blur px-3 py-2 rounded-xl shadow-md border border-slate-100 text-[10px] font-bold text-slate-600">
        <span className="text-[#4361ee] font-black">{buses.filter(b => b.lat || b.latitude).length}</span> unidades ·{' '}
        <span className="text-secondary font-black">{visibleStudents.filter(s => (s.stopLat || s.lat) && (s.stopLng || s.lng)).length}</span> paradas
      </div>
    </div>
  );
}
