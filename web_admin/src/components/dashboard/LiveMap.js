"use client";
import React, { useEffect, useState, useMemo, useRef, useCallback } from "react";
import Map, { Marker, Source, Layer, Popup } from "react-map-gl/maplibre";
import {
  decodePolyline,
  parseLatLng,
  resolveMapCenter,
  DEFAULT_MAP_CENTER,
  MAP_VECTOR_STREETS_STYLE,
  MAP_VECTOR_SATELLITE_STYLE,
} from "@/lib/polyline";

function BusMarker({ isActive, routeLabel = "" }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", cursor: "pointer" }}>
      {routeLabel ? (
        <span
          style={{
            fontSize: 9,
            fontWeight: 800,
            color: "#1e3a8a",
            background: "white",
            padding: "1px 6px",
            borderRadius: 8,
            marginBottom: 2,
            boxShadow: "0 1px 4px rgba(0,0,0,.15)",
          }}
        >
          {routeLabel}
        </span>
      ) : null}
      <div
        style={{
          width: 44,
          height: 44,
          background: isActive ? "#4361ee" : "#94a3b8",
          borderRadius: "50%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          border: "3px solid white",
          boxShadow: "0 2px 8px rgba(0,0,0,0.3)",
        }}
      >
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="white">
          <path d="M4 16c0 .88.39 1.67 1 2.22V20c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h8v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1.78c.61-.55 1-1.34 1-2.22V6c0-3.5-3.58-4-8-4s-8 .5-8 4v10zm3.5 1c-.83 0-1.5-.67-1.5-1.5S6.67 14 7.5 14s1.5.67 1.5 1.5S8.33 17 7.5 17zm9 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zm1.5-6H6V6h12v5z" />
        </svg>
      </div>
    </div>
  );
}

function HouseMarker() {
  return (
    <div
      style={{
        width: 36,
        height: 36,
        background: "#5d5a85",
        borderRadius: "50%",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        border: "2.5px solid white",
        boxShadow: "0 2px 6px rgba(0,0,0,0.25)",
        cursor: "pointer",
      }}
    >
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="white">
        <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z" />
      </svg>
    </div>
  );
}

function SchoolMarker() {
  return (
    <div
      style={{
        width: 52,
        height: 52,
        background: "#f59e0b",
        borderRadius: "50%",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        border: "3px solid white",
        boxShadow: "0 3px 10px rgba(0,0,0,0.3)",
        cursor: "pointer",
      }}
    >
      <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="white">
        <path d="M5 13.18v4L12 21l7-3.82v-4L12 17l-7-3.82zM12 3 1 9l11 6 9-4.91V17h2V9L12 3z" />
      </svg>
    </div>
  );
}

function ActiveBusHalo() {
  return (
    <div
      style={{
        width: 120,
        height: 120,
        borderRadius: "50%",
        background: "rgba(67, 97, 238, 0.12)",
        border: "1px solid rgba(67, 97, 238, 0.35)",
        transform: "translate(-50%, -50%)",
        pointerEvents: "none",
      }}
    />
  );
}

export default function LiveMap({
  buses,
  students,
  schoolCenter,
  schoolName,
  schoolAddress,
  routeByDriver = {},
  showStudents = true,
  mapHeight = "min(68vh, 620px)",
}) {
  const [isMounted, setIsMounted] = useState(false);
  const [mapType, setMapType] = useState("road");
  const [popup, setPopup] = useState(null);
  const mapRef = useRef(null);
  const lastCenterKeyRef = useRef("");

  const centerLat = parseLatLng(schoolCenter?.lat);
  const centerLng = parseLatLng(schoolCenter?.lng);
  const mapCenter = useMemo(
    () => resolveMapCenter(schoolCenter?.lat, schoolCenter?.lng, DEFAULT_MAP_CENTER),
    [schoolCenter?.lat, schoolCenter?.lng]
  );
  const hasSchoolPin = centerLat != null && centerLng != null;
  const visibleStudents = showStudents ? students : [];

  const mapStyle = mapType === "satellite" ? MAP_VECTOR_SATELLITE_STYLE : MAP_VECTOR_STREETS_STYLE;

  const initialViewState = useMemo(
    () => ({
      longitude: mapCenter[1],
      latitude: mapCenter[0],
      zoom: 15,
    }),
    [mapCenter]
  );

  useEffect(() => {
    const timer = setTimeout(() => setIsMounted(true), 0);
    return () => clearTimeout(timer);
  }, []);

  const flyToTarget = useCallback(() => {
    const map = mapRef.current?.getMap?.();
    if (!map) return;

    const activeBus = buses.find((b) => {
      const blat = parseLatLng(b.lat ?? b.latitude);
      const blng = parseLatLng(b.lng ?? b.longitude);
      return blat != null && blng != null;
    });

    let lat;
    let lng;
    let zoom = 15;

    if (activeBus) {
      lat = parseLatLng(activeBus.lat ?? activeBus.latitude);
      lng = parseLatLng(activeBus.lng ?? activeBus.longitude);
      zoom = 16;
    } else if (mapCenter[0] != null && mapCenter[1] != null) {
      [lat, lng] = mapCenter;
    } else {
      return;
    }

    const key = `${lat.toFixed(5)},${lng.toFixed(5)},${zoom}`;
    if (lastCenterKeyRef.current === key) return;
    lastCenterKeyRef.current = key;

    map.flyTo({ center: [lng, lat], zoom, duration: 0 });
  }, [buses, mapCenter]);

  useEffect(() => {
    if (!isMounted) return;
    flyToTarget();
  }, [isMounted, flyToTarget]);

  useEffect(() => {
    if (!isMounted) return;
    const map = mapRef.current?.getMap?.();
    if (!map) return;

    const fix = () => map.resize();
    const t1 = setTimeout(fix, 0);
    const t2 = setTimeout(fix, 250);
    window.addEventListener("resize", fix);
    return () => {
      clearTimeout(t1);
      clearTimeout(t2);
      window.removeEventListener("resize", fix);
    };
  }, [isMounted, mapHeight, mapType]);

  const formatTime = (ts) => {
    if (!ts) return "—";
    const d = ts.toDate ? ts.toDate() : new Date(ts);
    return d.toLocaleTimeString("es-EC", { hour: "2-digit", minute: "2-digit", second: "2-digit" });
  };

  const handleMapLoad = useCallback((evt) => {
    const map = evt.target;
    map.on("styleimagemissing", (e) => {
      if (map.hasImage(e.id)) return;
      const size = 1;
      map.addImage(e.id, { width: size, height: size, data: new Uint8Array(size * size * 4) });
    });
  }, []);

  const zoomIn = () => mapRef.current?.getMap()?.zoomIn({ duration: 200 });
  const zoomOut = () => mapRef.current?.getMap()?.zoomOut({ duration: 200 });

  const routeFeatures = useMemo(() => {
    return buses
      .filter((bus) => bus.fullRouteJson && bus.status === "on_route")
      .map((bus) => {
        const points = decodePolyline(bus.fullRouteJson);
        if (points.length < 2) return null;
        return {
          id: bus.id,
          type: "Feature",
          geometry: {
            type: "LineString",
            coordinates: points.map(([lat, lng]) => [lng, lat]),
          },
        };
      })
      .filter(Boolean);
  }, [buses]);

  if (!isMounted) {
    return (
      <div
        className="w-full bg-slate-100 animate-pulse rounded-2xl flex items-center justify-center text-slate-400 font-black uppercase tracking-widest italic"
        style={{ height: mapHeight }}
      >
        Iniciando Monitorización...
      </div>
    );
  }

  return (
    <div
      className="w-full rounded-2xl overflow-hidden border border-slate-200 shadow-lg relative bg-slate-100"
      style={{ height: mapHeight }}
    >
      <div className="absolute top-3 left-3 z-10 flex flex-col gap-2 pointer-events-none">
        <div className="bg-white rounded-xl shadow-md border border-slate-100 overflow-hidden flex pointer-events-auto w-fit">
          <button
            type="button"
            onClick={() => setMapType("road")}
            className={`px-3 py-2 text-[10px] font-black uppercase ${mapType === "road" ? "bg-[#4361ee] text-white" : "text-slate-600 hover:bg-slate-50"}`}
          >
            Calles
          </button>
          <button
            type="button"
            onClick={() => setMapType("satellite")}
            className={`px-3 py-2 text-[10px] font-black uppercase border-l border-slate-100 ${mapType === "satellite" ? "bg-[#4361ee] text-white" : "text-slate-600 hover:bg-slate-50"}`}
          >
            Satélite
          </button>
        </div>
        <div className="bg-white rounded-xl shadow-md border border-slate-100 overflow-hidden flex flex-col pointer-events-auto w-9">
          <button
            type="button"
            onClick={zoomIn}
            aria-label="Acercar mapa"
            className="h-9 flex items-center justify-center text-lg font-bold text-slate-700 hover:bg-slate-50"
          >
            +
          </button>
          <button
            type="button"
            onClick={zoomOut}
            aria-label="Alejar mapa"
            className="h-9 flex items-center justify-center text-lg font-bold text-slate-700 hover:bg-slate-50 border-t border-slate-100"
          >
            −
          </button>
        </div>
      </div>

      {!hasSchoolPin && (
        <div className="absolute top-[7.5rem] left-3 right-4 z-10 bg-amber-50 border border-amber-200 text-amber-900 text-xs font-medium px-3 py-2 rounded-xl shadow-sm">
          Este colegio no tiene ubicacion configurada. El mapa usa una vista general. Un super admin puede fijarla en Instituciones → Credenciales → Ubicacion.
        </div>
      )}

      <Map
        ref={mapRef}
        mapStyle={mapStyle}
        initialViewState={initialViewState}
        style={{ width: "100%", height: "100%" }}
        scrollZoom
        dragPan
        doubleClickZoom
        touchZoomRotate
        attributionControl
        onLoad={handleMapLoad}
        onClick={() => setPopup(null)}
      >
        {routeFeatures.length > 0 && (
          <Source
            id="active-routes"
            type="geojson"
            data={{ type: "FeatureCollection", features: routeFeatures }}
          >
            <Layer
              id="active-routes-line"
              type="line"
              paint={{
                "line-color": "#4361ee",
                "line-width": 5,
                "line-opacity": 0.85,
              }}
            />
          </Source>
        )}

        <Marker
          longitude={mapCenter[1]}
          latitude={mapCenter[0]}
          anchor="center"
          onClick={(e) => {
            e.originalEvent.stopPropagation();
            setPopup({
              kind: "school",
              lng: mapCenter[1],
              lat: mapCenter[0],
            });
          }}
        >
          <SchoolMarker />
        </Marker>

        {visibleStudents.map((student) => {
          const lat = parseLatLng(student.stopLat ?? student.lat);
          const lng = parseLatLng(student.stopLng ?? student.lng);
          if (lat == null || lng == null) return null;
          return (
            <Marker
              key={student.id}
              longitude={lng}
              latitude={lat}
              anchor="center"
              onClick={(e) => {
                e.originalEvent.stopPropagation();
                setPopup({
                  kind: "student",
                  lng,
                  lat,
                  student,
                });
              }}
            >
              <HouseMarker />
            </Marker>
          );
        })}

        {buses.map((bus) => {
          const lat = parseLatLng(bus.lat ?? bus.latitude);
          const lng = parseLatLng(bus.lng ?? bus.longitude);
          if (lat == null || lng == null) return null;
          const isActive = bus.status === "on_route";
          const routeInfo = routeByDriver[bus.driverId || bus.id] || {};
          const routeLabel = routeInfo.name ? `R-${String(routeInfo.name).slice(0, 8)}` : "";
          const studentCount = routeInfo.studentCount ?? 0;
          return (
            <React.Fragment key={bus.id}>
              {isActive && (
                <Marker longitude={lng} latitude={lat} anchor="center">
                  <ActiveBusHalo />
                </Marker>
              )}
              <Marker
                longitude={lng}
                latitude={lat}
                anchor="center"
                onClick={(e) => {
                  e.originalEvent.stopPropagation();
                  setPopup({
                    kind: "bus",
                    lng,
                    lat,
                    bus,
                    routeInfo,
                    studentCount,
                    isActive,
                  });
                }}
              >
                <BusMarker isActive={isActive} routeLabel={routeLabel} />
              </Marker>
            </React.Fragment>
          );
        })}

        {popup?.kind === "school" && (
          <Popup
            longitude={popup.lng}
            latitude={popup.lat}
            anchor="bottom"
            closeButton
            closeOnClick={false}
            onClose={() => setPopup(null)}
          >
            <div className="text-center p-2 min-w-[160px]">
              <p className="font-extrabold text-primary text-base">{schoolName || "COLEGIO"}</p>
              <p className="text-xs text-slate-500 italic mt-1">{schoolAddress || "Sede educativa"}</p>
              <span className="bg-primary/10 text-primary text-xs px-2 py-0.5 rounded-full font-black mt-2 inline-block">
                CENTRO DE OPERACIONES
              </span>
            </div>
          </Popup>
        )}

        {popup?.kind === "student" && (
          <Popup
            longitude={popup.lng}
            latitude={popup.lat}
            anchor="bottom"
            closeButton
            closeOnClick={false}
            onClose={() => setPopup(null)}
          >
            <div className="p-2 min-w-[160px]">
              <p className="font-black text-on-surface text-sm leading-none">
                {popup.student.studentName || popup.student.name || "Estudiante"}
              </p>
              <p className="text-xs text-slate-500 font-bold mt-0.5 uppercase">
                {popup.student.grade || popup.student.curso || "—"}
              </p>
              <div className="mt-2 bg-slate-50 rounded-lg p-2 text-xs text-slate-600">
                <span className="font-black text-primary">Parada registrada</span>
                <br />
                {popup.lat.toFixed(5)}, {popup.lng.toFixed(5)}
              </div>
            </div>
          </Popup>
        )}

        {popup?.kind === "bus" && (
          <Popup
            longitude={popup.lng}
            latitude={popup.lat}
            anchor="bottom"
            closeButton
            closeOnClick={false}
            onClose={() => setPopup(null)}
          >
            <div className="p-3 min-w-[200px]">
              <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">
                {popup.routeInfo.name ? `Ruta ${popup.routeInfo.name}` : "Unidad activa"}
              </p>
              <p className="font-extrabold text-[#4361ee] text-sm">{popup.bus.driverName || "Conductor"}</p>
              <div className="mt-2 space-y-1 text-xs text-slate-600">
                <p>
                  <span className="font-bold">Estudiantes:</span> {popup.studentCount}
                </p>
                {popup.bus.speed != null && (
                  <p>
                    <span className="font-bold">Velocidad:</span> {parseFloat(popup.bus.speed).toFixed(0)} km/h
                  </p>
                )}
                <p>
                  <span className="font-bold">Actualizado:</span>{" "}
                  {formatTime(popup.bus.lastUpdated || popup.bus.updatedAt || popup.bus.timestamp)}
                </p>
              </div>
              <span
                className={`inline-block mt-2 px-2 py-0.5 rounded-full text-[10px] font-black uppercase ${popup.isActive ? "bg-emerald-100 text-emerald-700" : "bg-slate-100 text-slate-500"}`}
              >
                {popup.isActive ? "A tiempo" : "Detenido"}
              </span>
            </div>
          </Popup>
        )}
      </Map>

      <div className="absolute top-4 right-4 z-10 bg-white/90 backdrop-blur px-3 py-2 rounded-xl shadow-md border border-slate-100 text-[10px] font-bold text-slate-600">
        <span className="text-[#4361ee] font-black">
          {buses.filter((b) => parseLatLng(b.lat ?? b.latitude) != null).length}
        </span>{" "}
        unidades ·{" "}
        <span className="text-secondary font-black">
          {visibleStudents.filter((s) => parseLatLng(s.stopLat ?? s.lat) != null).length}
        </span>{" "}
        paradas
      </div>
    </div>
  );
}
