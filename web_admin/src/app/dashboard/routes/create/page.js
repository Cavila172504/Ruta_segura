'use client';

import { useState, useEffect } from 'react';
import { db } from '../../../../lib/firebase';
import { collection, addDoc, getDocs, serverTimestamp, query, where } from 'firebase/firestore';
import { Search, Save, Download, Users, Truck, Clock, Trash2, MapPin, CheckCircle2, XCircle, Copy } from 'lucide-react';
import * as XLSX from 'xlsx';

export default function CreateRoutePage() {
  const [routeName, setRouteName] = useState('NUEVA RUTA CADE');
  const [shift, setShift] = useState('MATUTINA');
  const [students, setStudents] = useState([]);
  const [selectedStudents, setSelectedStudents] = useState([]);
  const [loading, setLoading] = useState(false);
  
  // Configuración de Entrada
  const [entryConfig, setEntryConfig] = useState({
    capacity: 17,
    unitName: 'P1',
    door: 'CUENCA',
    driver: 'GINA CARVAJAL'
  });

  // Configuración de Salida
  const [exitConfig, setExitConfig] = useState({
    sameAsEntry: true,
    capacity: 17,
    unitName: 'P1',
    door: 'CUENCA',
    driver: 'GINA CARVAJAL'
  });

  const days = ['L', 'M', 'MI', 'J', 'V', 'S', 'D'];

  useEffect(() => {
    fetchStudents();
  }, []);

  const fetchStudents = async () => {
    const q = query(collection(db, 'companies', 'CAD31', 'students'));
    const snapshot = await getDocs(q);
    const list = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      matrix: days.reduce((acc, day) => ({ ...acc, [day]: { entrance: true, exit: true } }), {})
    }));
    setStudents(list);
  };

  const exportToExcel = () => {
    const dataToExport = selectedStudents.map((s, index) => {
      const row = {
        '#': index + 1,
        'Estudiante': s.studentName,
        'Grado': s.grade || 'N/A',
        'Cédula Representante': s.cedulaPadre,
        'Representante': s.parentName || 'N/A',
        'Tipo de Servicio': s.serviceType || 'Completo'
      };
      days.forEach(day => {
        row[day] = (s.matrix[day].entrance ? 'E' : '') + (s.matrix[day].exit ? 'S' : '');
      });
      return row;
    });

    const worksheet = XLSX.utils.json_to_sheet(dataToExport);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, "Ruta");
    XLSX.writeFile(workbook, `${routeName}_Reporte.xlsx`);
  };

  const toggleStudentSelection = (student) => {
    const exists = selectedStudents.find(s => s.id === student.id);
    if (exists) {
      setSelectedStudents(selectedStudents.filter(s => s.id !== student.id));
    } else {
      setSelectedStudents([...selectedStudents, student]);
    }
  };

  const updateMatrix = (studentId, day, type) => {
    setSelectedStudents(prev => prev.map(s => {
      if (s.id === studentId) {
        return {
          ...s,
          matrix: {
            ...s.matrix,
            [day]: { ...s.matrix[day], [type]: !s.matrix[day][type] }
          }
        };
      }
      return s;
    }));
  };

  const handleSave = async () => {
    setLoading(true);
    try {
      await addDoc(collection(db, 'companies', 'CAD31', 'routes'), {
        name: routeName,
        shift,
        entryConfig,
        exitConfig,
        students: selectedStudents,
        createdAt: serverTimestamp(),
        status: 'active'
      });
      alert('¡Ruta creada exitosamente!');
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#0a0c0b] text-white p-8">
      {/* HEADER E ACCIONES PRINCIPALES */}
      <div className="flex justify-between items-center mb-10">
        <div>
          <h1 className="text-3xl font-black text-emerald-400 tracking-tight">ARQUITECTO DE RUTAS</h1>
          <p className="text-gray-400 text-sm">Configuración de trayectorias predefinidas para Colegio CADE</p>
        </div>
        <div className="flex gap-4">
          <button 
            onClick={exportToExcel}
            className="flex items-center gap-2 px-6 py-3 bg-white/5 border border-white/10 hover:bg-emerald-500/10 hover:border-emerald-500/50 rounded-2xl transition-all duration-300"
          >
            <Download className="w-4 h-4 text-emerald-400" />
            <span className="font-bold text-sm">EXPORTAR EXCEL</span>
          </button>
          <button 
            onClick={handleSave}
            disabled={loading}
            className="flex items-center gap-2 px-8 py-3 bg-emerald-500 hover:bg-emerald-400 text-black rounded-2xl font-black transition-all duration-300 shadow-lg shadow-emerald-500/20"
          >
            <Save className="w-4 h-4" />
            {loading ? 'GUARDANDO...' : 'GUARDAR RUTA'}
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-8">
        
        {/* PANEL DE CONFIGURACIÓN DE RUTA */}
        <div className="xl:col-span-1 space-y-6">
          <div className="bg-[#141817] p-8 rounded-[32px] border border-white/5 shadow-2xl">
            <h2 className="text-lg font-bold mb-6 flex items-center gap-3">
              <Truck className="w-5 h-5 text-emerald-400" />
              DATOS DE LA RUTA
            </h2>

            <div className="space-y-4">
              <div>
                <label className="text-[10px] font-black text-emerald-400/50 block mb-2 tracking-widest uppercase">Nombre de la Ruta</label>
                <input 
                  value={routeName}
                  onChange={(e) => setRouteName(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 focus:outline-none focus:border-emerald-500 transition-colors"
                />
              </div>

              <div>
                <label className="text-[10px] font-black text-emerald-400/50 block mb-2 tracking-widest uppercase">Jornada de Trabajo</label>
                <select 
                  value={shift}
                  onChange={(e) => setShift(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 focus:outline-none focus:border-emerald-500 transition-colors"
                >
                  <option value="MATUTINA">MATUTINA</option>
                  <option value="VESPERTINA">VESPERTINA</option>
                  <option value="NOCTURNA">NOCTURNA</option>
                </select>
              </div>
            </div>

            {/* SECCIÓN ENTRADA */}
            <div className="mt-8 pt-8 border-t border-white/5">
              <h3 className="text-sm font-black text-emerald-400 mb-4 flex items-center gap-2">
                <Clock className="w-4 h-4" />
                RECORRIDO DE ENTRADA
              </h3>
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-white/5 p-4 rounded-xl border border-white/5">
                  <span className="text-[9px] text-gray-400 block mb-1">CAPACIDAD</span>
                  <input type="number" value={entryConfig.capacity} className="bg-transparent font-bold w-full focus:outline-none" />
                </div>
                <div className="bg-white/5 p-4 rounded-xl border border-white/5">
                  <span className="text-[9px] text-gray-400 block mb-1">UNIDAD</span>
                  <input value={entryConfig.unitName} className="bg-transparent font-bold w-full focus:outline-none" />
                </div>
              </div>
            </div>

            {/* SECCIÓN SALIDA */}
            <div className="mt-6 pt-6 border-t border-white/5">
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-sm font-black text-emerald-400 flex items-center gap-2">
                  <Clock className="w-4 h-4" />
                  RECORRIDO DE SALIDA
                </h3>
                <label className="flex items-center gap-2 text-[10px] text-gray-400 cursor-pointer">
                  <input 
                    type="checkbox" 
                    checked={exitConfig.sameAsEntry}
                    onChange={(e) => setExitConfig({...exitConfig, sameAsEntry: e.target.checked})}
                    className="accent-emerald-500" 
                  />
                  Mismo conductor
                </label>
              </div>
              <div className="bg-white/5 p-4 rounded-xl border border-white/5">
                <span className="text-[9px] text-gray-400 block mb-1">CONDUCTOR ASIGNADO</span>
                <p className="font-bold text-sm text-gray-300">
                  {exitConfig.sameAsEntry ? entryConfig.driver : exitConfig.driver}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* PANEL DE ASIGNACIÓN DE ESTUDIANTES */}
        <div className="xl:col-span-2 space-y-6">
          <div className="bg-[#141817] p-8 rounded-[32px] border border-white/5 shadow-2xl overflow-hidden">
            <div className="flex justify-between items-center mb-8">
              <h2 className="text-lg font-bold flex items-center gap-3">
                <Users className="w-5 h-5 text-emerald-400" />
                DATOS DE ESTUDIANTES ({selectedStudents.length})
              </h2>
              <div className="relative">
                <Search className="w-4 h-4 absolute left-4 top-1/2 -translate-y-1/2 text-gray-500" />
                <input 
                  placeholder="Buscar estudiante..." 
                  className="bg-white/5 border border-white/10 rounded-full pl-12 pr-6 py-2 text-sm focus:outline-none focus:border-emerald-500"
                />
              </div>
            </div>

            {/* TABLA DE MATRIX DE ASISTENCIA */}
            <div className="overflow-x-auto">
              <table className="w-full text-left border-separate border-spacing-y-2">
                <thead>
                  <tr className="text-[10px] font-black text-emerald-400 uppercase tracking-widest italic">
                    <th className="px-4 py-2">Estado</th>
                    <th className="px-4 py-2">Estudiante / Grado</th>
                    {days.map(day => <th key={day} className="px-1 text-center">{day}</th>)}
                    <th className="px-1 text-center"></th>
                  </tr>
                </thead>
                <tbody>
                  {students.map((student) => {
                    const isSelected = selectedStudents.some(s => s.id === student.id);
                    const currentStudent = selectedStudents.find(s => s.id === student.id) || student;
                    
                    return (
                      <tr 
                        key={student.id}
                        className={`transition-all duration-300 group ${isSelected ? 'bg-emerald-500/5' : 'hover:bg-white/5'}`}
                      >
                        <td className="px-4 py-4 first:rounded-l-2xl">
                          <button 
                            onClick={() => toggleStudentSelection(student)}
                            className={`w-6 h-6 rounded-lg border-2 flex items-center justify-center transition-all ${isSelected ? 'bg-emerald-500 border-emerald-500' : 'border-white/20'}`}
                          >
                            {isSelected && <CheckCircle2 className="w-4 h-4 text-black" />}
                          </button>
                        </td>
                        <td className="px-4 py-4">
                          <p className="font-bold text-sm group-hover:text-emerald-400 transition-colors uppercase">{student.studentName}</p>
                          <p className="text-[10px] text-gray-500 font-bold">{student.grade || 'SIN GRADO'}</p>
                        </td>
                        {days.map(day => (
                          <td key={day} className="px-1 text-center">
                            <div className="flex flex-col gap-1 items-center">
                              <button 
                                disabled={!isSelected}
                                onClick={() => updateMatrix(student.id, day, 'entrance')}
                                className={`w-6 h-6 text-[8px] font-black rounded flex items-center justify-center border transition-all ${isSelected ? (currentStudent.matrix[day].entrance ? 'bg-emerald-500 border-emerald-500 text-black' : 'border-white/10 text-gray-500 hover:border-emerald-500/50') : 'opacity-20'}`}
                              >
                                E
                              </button>
                              <button 
                                disabled={!isSelected}
                                onClick={() => updateMatrix(student.id, day, 'exit')}
                                className={`w-6 h-6 text-[8px] font-black rounded flex items-center justify-center border transition-all ${isSelected ? (currentStudent.matrix[day].exit ? 'bg-amber-500 border-amber-500 text-black' : 'border-white/10 text-gray-500 hover:border-amber-500/50') : 'opacity-20'}`}
                              >
                                S
                              </button>
                            </div>
                          </td>
                        ))}
                        <td className="px-4 py-4 last:rounded-r-2xl text-right">
                          <button className="p-2 text-gray-600 hover:text-red-500 transition-colors">
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
