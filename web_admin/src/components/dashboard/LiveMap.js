"use client";
import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// Fix for default marker icons in Leaflet + Next.js
const iconStudent = new L.Icon({
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/1233/1233939.png', // Casa icon
    iconSize: [32, 32],
    iconAnchor: [16, 32],
    popupAnchor: [0, -32]
});

const iconBus = new L.Icon({
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/3448/3448339.png', // Bus icon
    iconSize: [40, 40],
    iconAnchor: [20, 20],
    popupAnchor: [0, -20]
});

const iconSchool = new L.Icon({
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/2602/2602414.png', // School icon (CADE)
    iconSize: [50, 50],
    iconAnchor: [25, 50],
    popupAnchor: [0, -50]
});

function ChangeView({ center, zoom }) {
  const map = useMap();
  useEffect(() => {
    map.setView(center, zoom);
  }, [center, zoom, map]);
  return null;
}

export default function LiveMap({ buses, students }) {
  const [isMounted, setIsMounted] = useState(false);
  
  // COORDENADAS COLEGIO CADE (Santo Domingo, Vía Quevedo Km 14.5)
  const cadeCenter = [-0.3485881, -79.2477156]; 

  useEffect(() => {
    setIsMounted(true);
  }, []);

  if (!isMounted) return <div className="w-full h-[500px] bg-slate-100 animate-pulse rounded-2xl flex items-center justify-center text-slate-400 font-black uppercase tracking-widest italic">Iniciando Monitorización...</div>;

  return (
    <div className="w-full h-[600px] rounded-3xl overflow-hidden border-4 border-white shadow-2xl relative">
      <MapContainer 
        center={cadeCenter} 
        zoom={15} 
        style={{ height: '100%', width: '100%' }}
        scrollWheelZoom={true}
      >
        {/* Usamos una capa de mapa que se parece mucho a Google Maps (Clean & Fresh) */}
        <TileLayer
          attribution='&copy; Google Maps Style'
          url="https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}"
        />
        <ChangeView center={cadeCenter} zoom={15} />

        {/* MARCADOR DEL COLEGIO CADE (Punto Central) */}
        <Marker 
            position={cadeCenter} 
            icon={iconSchool}
        >
            <Popup>
                <div className="text-center p-2">
                    <img 
                        src="https://educacionadventista.com/wp-content/uploads/2021/04/LOGO-EDUCACION-ADVENTISTA.png" 
                        alt="CADE Logo" 
                        className="w-20 mx-auto mb-2"
                    />
                    <p className="font-extrabold text-primary text-base">COLEGIO CADE</p>
                    <p className="text-[10px] font-bold text-slate-500 italic">Km 14 1/2 vía Quevedo</p>
                    <span className="bg-primary/10 text-primary text-[9px] px-2 py-0.5 rounded-full font-black mt-2 inline-block">CENTRO DE OPERACIONES</span>
                </div>
            </Popup>
        </Marker>

        {/* Marcadores de Estudiantes (Registros de Padres) */}
        {students.map((student) => {
            if (student.stopLat && student.stopLng) {
                return (
                    <Marker 
                        key={student.id} 
                        position={[student.stopLat, student.stopLng]} 
                        icon={iconStudent}
                    >
                        <Popup>
                            <div className="p-3 min-w-[150px]">
                                <div className="flex items-center gap-2 mb-2">
                                    <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center border border-slate-200">
                                        <span className="material-symbols-outlined text-sm text-slate-400">person</span>
                                    </div>
                                    <div>
                                        <p className="font-black text-on-surface text-xs leading-none">{student.name}</p>
                                        <p className="text-[9px] text-slate-500 font-bold uppercase">{student.grade}</p>
                                    </div>
                                </div>
                                <div className="space-y-1">
                                    <div className="flex items-center justify-between bg-slate-50 p-1.5 rounded-lg border border-slate-100">
                                        <span className="text-[9px] font-black text-slate-400 uppercase">Unidad</span>
                                        <span className="text-[9px] font-black text-primary">{student.busUnit || 'PENDIENTE'}</span>
                                    </div>
                                    <button className="w-full py-2 bg-primary text-white text-[9px] font-black uppercase rounded-lg shadow-sm mt-1">Ver Hoja de Ruta</button>
                                </div>
                            </div>
                        </Popup>
                    </Marker>
                );
            }
            return null;
        })}

        {/* Marcadores de Buses (Seguimiento en Vivo) */}
        {buses.map((bus) => {
            if (bus.lat && bus.lng) {
                return (
                    <Marker 
                        key={bus.id} 
                        position={[bus.lat, bus.lng]} 
                        icon={iconBus}
                    >
                        <Popup>
                            <div className="p-2">
                                <p className="font-extrabold text-sm text-primary mb-1">BUS: {bus.unitCode}</p>
                                <div className="flex items-center gap-1 mb-2">
                                    <span className="material-symbols-outlined text-xs text-slate-400">person</span>
                                    <p className="text-[10px] font-black uppercase text-on-surface">{bus.driverName || 'Conductor asignado'}</p>
                                </div>
                                <div className="flex items-center gap-2">
                                    <div className={`w-2 h-2 rounded-full ${bus.status === 'on_route' ? 'bg-emerald-500 animate-pulse' : 'bg-slate-300'}`}></div>
                                    <p className={`text-[9px] font-black uppercase tracking-widest ${bus.status === 'on_route' ? 'text-emerald-600' : 'text-slate-400'}`}>
                                        {bus.status === 'on_route' ? 'TRANSPORTE EN RUTA' : 'UNIDAD DETENIDA'}
                                    </p>
                                </div>
                            </div>
                        </Popup>
                    </Marker>
                );
            }
            return null;
        })}
      </MapContainer>
      
      {/* Overlay de información sobre el mapa */}
      <div className="absolute bottom-6 left-6 z-[1000] bg-white/90 backdrop-blur-md p-4 rounded-2xl shadow-xl border border-white max-w-[200px]">
         <p className="text-[10px] font-black text-slate-500 uppercase tracking-tighter mb-1">Ubicación Actual</p>
         <p className="text-xs font-bold text-on-surface">Santo Domingo, Ecuador</p>
         <p className="text-[9px] text-slate-400 italic">Vía Quevedo Km 14.5</p>
      </div>
    </div>
  );
}
