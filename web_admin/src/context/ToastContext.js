"use client";

import { createContext, useCallback, useContext, useState } from "react";

const ToastContext = createContext(null);

function ToastContainer({ toasts, onDismiss }) {
  if (!toasts.length) return null;

  return (
    <div
      className="fixed bottom-6 left-1/2 z-[100] flex w-[min(92vw,420px)] -translate-x-1/2 flex-col gap-2"
      aria-live="polite"
    >
      {toasts.map((toast) => (
        <div
          key={toast.id}
          className={`flex items-start gap-3 rounded-2xl border px-4 py-3 shadow-lg backdrop-blur-md ${
            toast.type === "success"
              ? "border-emerald-200 bg-emerald-50/95 text-emerald-900"
              : toast.type === "error"
                ? "border-rose-200 bg-rose-50/95 text-rose-900"
                : "border-slate-200 bg-white/95 text-slate-800"
          }`}
        >
          <span className="material-symbols-outlined text-lg shrink-0 mt-0.5">
            {toast.type === "success" ? "check_circle" : toast.type === "error" ? "error" : "info"}
          </span>
          <p className="flex-1 text-sm font-semibold leading-snug">{toast.message}</p>
          <button
            type="button"
            onClick={() => onDismiss(toast.id)}
            className="shrink-0 text-current opacity-60 hover:opacity-100"
            aria-label="Cerrar notificacion"
          >
            <span className="material-symbols-outlined text-lg">close</span>
          </button>
        </div>
      ))}
    </div>
  );
}

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);

  const dismiss = useCallback((id) => {
    setToasts((prev) => prev.filter((toast) => toast.id !== id));
  }, []);

  const push = useCallback(
    (message, type = "info") => {
      const id = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
      setToasts((prev) => [...prev, { id, message, type }]);
      window.setTimeout(() => dismiss(id), 4500);
    },
    [dismiss],
  );

  const value = {
    toast: push,
    success: (message) => push(message, "success"),
    error: (message) => push(message, "error"),
    info: (message) => push(message, "info"),
  };

  return (
    <ToastContext.Provider value={value}>
      {children}
      <ToastContainer toasts={toasts} onDismiss={dismiss} />
    </ToastContext.Provider>
  );
}

export function useToast() {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error("useToast debe usarse dentro de ToastProvider");
  }
  return context;
}