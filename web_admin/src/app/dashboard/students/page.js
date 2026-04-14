"use client";
import React, { useState, useEffect } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { collection, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db } from '@/lib/firebase';

const StudentsPage = () => {
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  const SCHOOL_CODE = 'CAD31';

  useEffect(() => {
    const studentsRef = collection(db, 'companies', SCHOOL_CODE, 'students');
    const q = query(studentsRef, orderBy('createdAt', 'desc'));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const list = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setStudents(list);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const filteredStudents = students.filter(s => 
    s.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    s.id?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <DashboardLayout title="Gestión de Estudiantes">
      <section className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-10">
        <div>
          <h2 className="text-3xl font-extrabold text-on-surface tracking-tight mb-2">Estudiantes ({SCHOOL_CODE})</h2>
          <p className="text-on-surface-variant max-w-md">Listado de alumnos vinculados a través de la App de Padres.</p>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative min-w-[300px]">
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 material-symbols-outlined text-xl">search</span>
            <input 
              type="text"
              className="w-full pl-10 pr-4 py-2.5 bg-surface-container-lowest border-none rounded-xl text-sm focus:ring-2 focus:ring-primary/20 shadow-sm outline-none"
              placeholder="Buscar estudiante..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>
      </section>

      <div className="bg-surface-container-lowest rounded-3xl overflow-hidden shadow-sm border border-outline-variant/10">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low/50">
                <th className="px-6 py-5 text-xs font-bold text-on-surface-variant uppercase tracking-widest">Estudiante</th>
                <th className="px-6 py-5 text-xs font-bold text-on-surface-variant uppercase tracking-widest">Grado / Curso</th>
                <th className="px-6 py-5 text-xs font-bold text-on-surface-variant uppercase tracking-widest text-center">Unidad</th>
                <th className="px-6 py-5 text-xs font-bold text-on-surface-variant uppercase tracking-widest text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-container">
              {filteredStudents.length === 0 ? (
                <tr>
                  <td colSpan="4" className="px-6 py-10 text-center text-slate-400">{loading ? 'Cargando...' : 'No se encontraron estudiantes.'}</td>
                </tr>
              ) : (
                filteredStudents.map((student) => (
                  <tr key={student.id} className="hover:bg-surface-bright transition-colors group">
                    <td className="px-6 py-5">
                      <div className="flex items-center gap-3">
                        <img 
                          alt="Student" 
                          className="w-10 h-10 rounded-full object-cover ring-2 ring-primary/10" 
                          src={student.photoUrl || "https://ui-avatars.com/api/?name=" + (student.name || 'S') + "&background=random"} 
                        />
                        <div>
                          <div className="font-bold text-on-surface text-sm">{student.name}</div>
                          <div className="text-[10px] text-slate-400 font-mono">ID: {student.id?.substring(0,8)}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-5">
                      <span className="text-xs font-bold text-slate-600 bg-slate-100 px-3 py-1 rounded-full">{student.grade || 'Pendiente'}</span>
                    </td>
                    <td className="px-6 py-5 text-center">
                      <span className="font-black text-primary uppercase text-sm">{student.busUnit || '---'}</span>
                    </td>
                    <td className="px-6 py-5 text-right space-x-2">
                       <button className="p-2 text-slate-400 hover:text-primary hover:bg-primary/5 rounded-lg transition-all">
                        <span className="material-symbols-outlined text-xl">visibility</span>
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </DashboardLayout>
  );
};

export default StudentsPage;
