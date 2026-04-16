"use client";
import React, { useState, useEffect } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { collection, onSnapshot, query, orderBy, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/context/AuthContext';

const SupportPage = () => {
  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('Abiertos');
  const [searchTerm, setSearchTerm] = useState('');

  const { profile, loading: authLoading } = useAuth();
  const SCHOOL_CODE = profile?.unitCode || 'CAD31';

  useEffect(() => {
    if (authLoading || !SCHOOL_CODE) return;

    const ticketsRef = collection(db, 'support_tickets');
    // En el futuro, los tickets de soporte deberían tener unitCode. 
    // Por ahora, si no tienen, los mostramos todos o filtramos si el esquema lo permite.
    // Asumiré que quieres filtrar por los que pertenecen a esta escuela.
    const q = query(ticketsRef, orderBy('timestamp', 'desc'));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const list = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setTickets(list);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [SCHOOL_CODE, authLoading]);

  const updateTicketStatus = async (id, newStatus) => {
    try {
      const ticketRef = doc(db, 'support_tickets', id);
      await updateDoc(ticketRef, { status: newStatus });
    } catch (error) {
      console.error("Error updating status:", error);
    }
  };

  const deleteTicket = async (id) => {
    if (confirm("¿Estás seguro de eliminar este registro de soporte?")) {
      try {
        await deleteDoc(doc(db, 'support_tickets', id));
      } catch (error) {
        console.error("Error deleting ticket:", error);
      }
    }
  };

  const filteredTickets = tickets.filter(ticket => {
    const matchesTab = activeTab === 'Todos' || 
                      (activeTab === 'Abiertos' && ticket.status === 'open') ||
                      (activeTab === 'Cerrados' && ticket.status === 'closed');
    
    const matchesSearch = ticket.parentName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         ticket.message?.toLowerCase().includes(searchTerm.toLowerCase());
                         
    const matchesUnit = !ticket.unitCode || ticket.unitCode === SCHOOL_CODE;
                         
    return matchesTab && matchesSearch && matchesUnit;
  });

  const formatDate = (timestamp) => {
    if (!timestamp) return '---';
    const date = timestamp.toDate();
    return date.toLocaleString('es-ES', { 
      day: '2-digit', month: '2-digit', year: 'numeric', 
      hour: '2-digit', minute: '2-digit' 
    });
  };

  return (
    <DashboardLayout title="Centro de Soporte">
      <div className="bg-white rounded-3xl shadow-xl shadow-slate-200/50 border border-slate-100 overflow-hidden">
        {/* Header con tabs */}
        <div className="px-8 pt-8 pb-0">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
            <h2 className="text-2xl font-black text-slate-800 tracking-tight">MENSAJES DE SOPORTE</h2>
            <div className="flex gap-2 bg-slate-100 p-1 rounded-2xl">
              {['Abiertos', 'Cerrados', 'Todos'].map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  className={`px-6 py-2 rounded-xl text-xs font-bold transition-all ${
                    activeTab === tab 
                      ? 'bg-white text-primary shadow-sm' 
                      : 'text-slate-500 hover:text-slate-700'
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>
          </div>

          {/* Buscador */}
          <div className="relative mb-6">
            <span className="absolute left-4 top-1/2 -translate-y-1/2 material-symbols-outlined text-slate-400">search</span>
            <input
              type="text"
              placeholder="Buscar por nombre o mensaje..."
              className="w-full pl-12 pr-6 py-4 bg-slate-50 rounded-2xl border-none focus:ring-2 focus:ring-primary/20 transition-all text-sm outline-none"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>

        {/* Tabla de Tickets */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50/50 border-y border-slate-100">
                <th className="px-8 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest">Fecha</th>
                <th className="px-8 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest">Representante</th>
                <th className="px-8 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest">Mensaje</th>
                <th className="px-8 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest">Estado</th>
                <th className="px-8 py-4 text-[10px] font-bold text-slate-400 uppercase tracking-widest text-center">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr><td colSpan="5" className="py-10 text-center text-slate-400 font-medium">Cargando mensajes...</td></tr>
              ) : filteredTickets.length === 0 ? (
                <tr><td colSpan="5" className="py-10 text-center text-slate-400 font-medium">No hay mensajes de soporte.</td></tr>
              ) : filteredTickets.map((ticket) => (
                <tr key={ticket.id} className="hover:bg-slate-50/50 transition-colors group">
                  <td className="px-8 py-6">
                    <div className="text-xs font-bold text-slate-400 tracking-tight">{formatDate(ticket.timestamp)}</div>
                  </td>
                  <td className="px-8 py-6">
                    <div className="text-sm font-bold text-slate-800 uppercase leading-none">{ticket.parentName}</div>
                    <div className="text-[10px] font-medium text-slate-400 mt-1 uppercase tracking-tighter">Padre / Representante</div>
                  </td>
                  <td className="px-8 py-6">
                    <div className="text-sm text-slate-600 max-w-md line-clamp-2">{ticket.message}</div>
                  </td>
                  <td className="px-8 py-6">
                    {ticket.status === 'open' ? (
                      <span className="bg-amber-100 text-amber-600 px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-wider">Pendiente</span>
                    ) : (
                      <span className="bg-emerald-100 text-emerald-600 px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-wider">Cerrado</span>
                    )}
                  </td>
                  <td className="px-8 py-6">
                    <div className="flex justify-center gap-3">
                      {ticket.status === 'open' ? (
                        <button 
                          onClick={() => updateTicketStatus(ticket.id, 'closed')}
                          title="Marcar como atendido"
                          className="bg-primary/10 text-primary hover:bg-primary hover:text-white px-3 py-1.5 rounded-xl text-[10px] font-bold transition-all uppercase tracking-tight"
                        >
                          Cerrar Ticket
                        </button>
                      ) : (
                        <button 
                          onClick={() => updateTicketStatus(ticket.id, 'open')}
                          title="Reabrir ticket"
                          className="bg-slate-100 text-slate-400 hover:bg-slate-200 px-3 py-1.5 rounded-xl text-[10px] font-bold transition-all uppercase tracking-tight"
                        >
                          Reabrir
                        </button>
                      )}
                      <button 
                        onClick={() => deleteTicket(ticket.id)}
                        className="p-2 text-slate-300 hover:text-red-500 transition-colors"
                        title="Eliminar registro"
                      >
                        <span className="material-symbols-outlined text-lg">delete</span>
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default SupportPage;
