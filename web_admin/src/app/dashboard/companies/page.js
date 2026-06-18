"use client";
import React, { useState, useEffect } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useAuth } from '@/context/AuthContext';
import { authFetch } from '@/lib/api-client';
import { fetchCompaniesStatsFromClient } from '@/lib/companies-client';
import { useRouter } from 'next/navigation';
import dynamic from 'next/dynamic';
import ResponsiveTable from '@/components/ui/ResponsiveTable';
import BillingStatusBadge from '@/components/ui/BillingStatusBadge';
import { useToast } from '@/context/ToastContext';
import { PLAN_PRESETS, usageTone, calculateMonthlyCharge } from '@/lib/billing';
import SchoolOnboardingGuide from '@/components/companies/SchoolOnboardingGuide';
import { collection, onSnapshot, query, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';

const CompanyLocationPicker = dynamic(
  () => import('@/components/companies/CompanyLocationPicker'),
  { ssr: false, loading: () => <div className="h-52 bg-slate-100 animate-pulse rounded-xl" /> }
);

function Modal({ open, onClose, title, subtitle, icon, accent = 'border-primary', children, footer, size = 'md' }) {
  if (!open) return null;
  const sizeClass = size === 'lg' ? 'max-w-2xl' : size === 'sm' ? 'max-w-sm' : 'max-w-lg';
  return (
    <div className="fixed inset-0 z-[1000] bg-black/40 backdrop-blur-sm flex items-center justify-center p-4">
      <div className={`bg-white rounded-2xl w-full ${sizeClass} shadow-2xl relative border-t-4 ${accent} flex flex-col max-h-[90vh]`} role="dialog" aria-modal="true">
        <div className="flex-shrink-0 px-6 pt-6 pb-4 border-b border-slate-100">
          <button type="button" onClick={onClose} className="absolute top-4 right-4 p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors" aria-label="Cerrar">
            <span className="material-symbols-outlined">close</span>
          </button>
          <div className="flex items-start gap-3 pr-10">
            {icon && (
              <div className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center flex-shrink-0">
                <span className="material-symbols-outlined text-primary">{icon}</span>
              </div>
            )}
            <div>
              <h3 className="text-lg font-bold text-slate-900">{title}</h3>
              {subtitle && <p className="text-sm text-slate-500 mt-0.5">{subtitle}</p>}
            </div>
          </div>
        </div>
        <div className="flex-1 overflow-y-auto px-6 py-5 min-h-0">{children}</div>
        {footer && (
          <div className="flex-shrink-0 px-6 py-4 border-t border-slate-100 bg-slate-50/50 rounded-b-2xl">{footer}</div>
        )}
      </div>
    </div>
  );
}

function CompanyActionsMenu({ company, onEnter, onDetail, onBilling, onCredentials, onUsers, onDelete }) {
  const [open, setOpen] = React.useState(false);
  const ref = React.useRef(null);

  React.useEffect(() => {
    if (!open) return;
    const handleClick = (e) => {
      if (ref.current && !ref.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, [open]);

  const items = [
    { label: 'Entrar al panel', icon: 'login', action: onEnter, className: 'text-emerald-700 hover:bg-emerald-50' },
    { label: 'Ver detalle', icon: 'visibility', action: onDetail, className: 'text-primary hover:bg-violet-50' },
    { label: 'Facturacion', icon: 'payments', action: onBilling, className: 'text-violet-700 hover:bg-violet-50' },
    { label: 'Credenciales', icon: 'lock_reset', action: onCredentials, className: 'text-slate-700 hover:bg-slate-50' },
    { label: 'Usuarios', icon: 'group', action: onUsers, className: 'text-sky-700 hover:bg-sky-50' },
    { label: 'Eliminar', icon: 'delete', action: onDelete, className: 'text-rose-600 hover:bg-rose-50', divider: true },
  ];

  return (
    <div className="relative inline-block" ref={ref}>
      <button type="button" onClick={() => setOpen((v) => !v)} className="p-2 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 transition-colors" aria-label="Acciones">
        <span className="material-symbols-outlined text-slate-600 text-xl">more_vert</span>
      </button>
      {open && (
        <div className="absolute right-0 top-full mt-1 z-50 w-52 bg-white rounded-xl border border-slate-200 shadow-lg py-1">
          {items.map((item) => (
            <React.Fragment key={item.label}>
              {item.divider && <div className="my-1 border-t border-slate-100" />}
              <button
                type="button"
                onClick={() => { setOpen(false); item.action(company); }}
                className={`w-full flex items-center gap-2.5 px-3 py-2.5 text-sm font-semibold transition-colors ${item.className}`}
              >
                <span className="material-symbols-outlined text-lg">{item.icon}</span>
                {item.label}
              </button>
            </React.Fragment>
          ))}
        </div>
      )}
    </div>
  );
}

function BillingNumberField({ label, name, value, onChange, onBlur, placeholder, inputMode = 'numeric' }) {
  return (
    <div className="space-y-1">
      <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">{label}</label>
      <input
        type="text"
        inputMode={inputMode}
        name={name}
        value={value}
        onChange={onChange}
        onBlur={onBlur}
        onFocus={(e) => e.target.select()}
        placeholder={placeholder}
        className="w-full p-3 bg-white border border-slate-200 rounded-xl text-sm font-bold focus:ring-2 focus:ring-violet-200 outline-none"
      />
    </div>
  );
}

const CompaniesPage = () => {
    const { profile, loading, setActiveUnitCode } = useAuth();
    const router = useRouter();
    const toast = useToast();

    const [companies, setCompanies] = useState([]);
    const [totals, setTotals] = useState(null);
    const [fetching, setFetching] = useState(true);
    const [loadError, setLoadError] = useState('');
    const [adminWarning, setAdminWarning] = useState('');
    const [detailCompany, setDetailCompany] = useState(null);

    const [showModal, setShowModal] = useState(false);
    const [createStep, setCreateStep] = useState('datos');
    const [isSaving, setIsSaving] = useState(false);
    const [errorMsg, setErrorMsg] = useState('');

    const [formData, setFormData] = useState({
        unitCode: '',
        companyName: '',
        transportCompany: '',
        adminName: '',
        adminEmail: '',
        adminPassword: '',
        schoolLat: null,
        schoolLng: null,
        schoolAddress: '',
    });

    const [showEditModal, setShowEditModal] = useState(false);
    const [editTab, setEditTab] = useState('general');
    const [editData, setEditData] = useState({
        unitCode: '',
        companyName: '',
        transportCompany: '',
        adminName: '',
        adminEmail: '',
        newPassword: '',
        schoolLat: null,
        schoolLng: null,
        schoolAddress: '',
    });

    // Estado para el diálogo personalizado de confirmación de eliminación
    const [confirmingDelete, setConfirmingDelete] = useState(null); // guarda el unitCode a eliminar
    const [isDeleting, setIsDeleting] = useState(false);

    const [showBillingModal, setShowBillingModal] = useState(false);
    const [createdSchool, setCreatedSchool] = useState(null);
    const [billingData, setBillingData] = useState({
        unitCode: '',
        companyName: '',
        plan: 'basic',
        pricePerStudentUsd: 0,
        status: 'active',
        studentLimit: 80,
        driverLimit: 2,
        studentsActive: 0,
    });
    const [billingFields, setBillingFields] = useState({
        pricePerStudentUsd: '',
        studentLimit: '',
        driverLimit: '',
    });

    const [schoolUsersCompany, setSchoolUsersCompany] = useState(null);
    const [schoolUsers, setSchoolUsers] = useState([]);
    const [schoolUserFormOpen, setSchoolUserFormOpen] = useState(false);
    const [schoolUserSaving, setSchoolUserSaving] = useState(false);
    const [schoolUserForm, setSchoolUserForm] = useState({
        name: '',
        email: '',
        password: '',
        role: 'viewer',
    });

    useEffect(() => {
        if (!loading && profile?.role !== 'super_admin') {
            router.push('/dashboard');
        } else if (profile?.role === 'super_admin') {
            fetchCompanies();
        }
    }, [loading, profile, router]);

    useEffect(() => {
        if (!schoolUsersCompany?.unitCode) {
            setSchoolUsers([]);
            return undefined;
        }
        const q = query(
            collection(db, 'users', 'admins', 'members'),
            where('unitCode', '==', schoolUsersCompany.unitCode)
        );
        return onSnapshot(q, (snapshot) => {
            setSchoolUsers(snapshot.docs.map((docSnap) => ({ id: docSnap.id, ...docSnap.data() })));
        });
    }, [schoolUsersCompany?.unitCode]);

    const fetchCompanies = async () => {
        try {
            setFetching(true);
            setLoadError('');
            setAdminWarning('');

            const healthRes = await fetch('/api/health');
            const health = await healthRes.json().catch(() => ({}));
            if (!health.adminReady) {
                setAdminWarning(
                    'Modo lectura: Firebase Admin no está en el servidor. Verás datos desde Firestore; crear colegios/conductores requiere configurar FIREBASE_SERVICE_ACCOUNT.'
                );
            }

            const res = await authFetch('/api/companies/stats');
            const data = await res.json();

            if (res.ok && data.companies) {
                setCompanies(data.companies);
                setTotals(data.totals);
                return;
            }

            if (res.status === 503 || res.status === 500) {
                const fallback = await fetchCompaniesStatsFromClient();
                setCompanies(fallback.companies);
                setTotals(fallback.totals);
                if (!fallback.companies.length) {
                    setLoadError(data.error || 'No hay colegios en Firestore o sin permisos de lectura.');
                }
                return;
            }

            setLoadError(data.error || `Error del servidor (${res.status})`);
            setCompanies([]);
            setTotals(null);
        } catch (error) {
            console.error('Error fetching companies', error);
            try {
                const fallback = await fetchCompaniesStatsFromClient();
                setCompanies(fallback.companies);
                setTotals(fallback.totals);
                setAdminWarning(
                    'Conexión API falló; mostrando datos en modo lectura desde Firestore.'
                );
            } catch (clientErr) {
                console.error(clientErr);
                setLoadError(
                    'No se pudo conectar con Firebase. Revisa login super admin, reglas Firestore y FIREBASE_SERVICE_ACCOUNT.'
                );
                setCompanies([]);
                setTotals(null);
            }
        } finally {
            setFetching(false);
        }
    };

    const enterAsSchool = (company) => {
        setActiveUnitCode(company.unitCode, company.name);
        router.push('/dashboard');
    };

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData({
            ...formData,
            [name]: name === 'unitCode' ? value.toUpperCase() : value,
        });
    };

    const handleCreate = async (e) => {
        e.preventDefault();
        if (formData.schoolLat == null || formData.schoolLng == null) {
            setErrorMsg('Marca la ubicación del colegio en el mapa.');
            return;
        }
        setIsSaving(true);
        setErrorMsg('');

        try {
            const res = await authFetch('/api/companies', {
                method: 'POST',
                body: JSON.stringify(formData)
            });
            const data = await res.json();

            if (!res.ok) {
                setErrorMsg(data.error || 'Ocurrió un error');
            } else {
                const saved = {
                  unitCode: data.unitCode || formData.unitCode.trim().toUpperCase(),
                  companyName: formData.companyName,
                  adminEmail: formData.adminEmail,
                  adminPassword: formData.adminPassword,
                };
                setShowModal(false);
                setCreateStep('datos');
                setFormData({
                  unitCode: '', companyName: '', transportCompany: '', adminName: '', adminEmail: '', adminPassword: '',
                  schoolLat: null, schoolLng: null, schoolAddress: '',
                });
                setCreatedSchool(saved);
                fetchCompanies();
            }
        } catch (err) {
            setErrorMsg('Error de red');
        } finally {
            setIsSaving(false);
        }
    };

    const handleDelete = async () => {
        if (!confirmingDelete) return;
        setIsDeleting(true);
        try {
            const res = await authFetch(`/api/companies?unitCode=${confirmingDelete}`, { method: 'DELETE' });
            const data = await res.json();
            if (!res.ok) {
                console.error('Error:', data.error);
            } else {
                toast.success('Colegio eliminado');
                fetchCompanies();
            }
        } catch (error) {
            console.error('Error de red al intentar eliminar:', error);
        } finally {
            setIsDeleting(false);
            setConfirmingDelete(null);
        }
    };

    const openBillingModal = (c) => {
        const billing = c.billing || {};
        const pricePerStudentUsd = c.pricePerStudentUsd ?? billing.pricePerStudentUsd ?? 0;
        const studentLimit = c.studentLimit ?? billing.studentLimit ?? 80;
        const driverLimit = c.driverLimit ?? billing.driverLimit ?? 2;
        setBillingData({
            unitCode: c.unitCode,
            companyName: c.name,
            plan: c.billingPlan || billing.plan || 'basic',
            pricePerStudentUsd,
            status: c.billingStatus || billing.status || 'active',
            studentLimit,
            driverLimit,
            studentsActive: c.studentsActive ?? 0,
        });
        setBillingFields({
            pricePerStudentUsd: String(pricePerStudentUsd),
            studentLimit: String(studentLimit),
            driverLimit: String(driverLimit),
        });
        setShowBillingModal(true);
        setDetailCompany(null);
        setErrorMsg('');
    };

    const billingPreviewTotal = calculateMonthlyCharge({
        billingStatus: billingData.status,
        studentsActive: billingData.studentsActive,
        pricePerStudentUsd: billingData.pricePerStudentUsd,
    });

    const handleBillingChange = (e) => {
        const { name, value } = e.target;
        setBillingData((prev) => ({ ...prev, [name]: value }));
    };

    const handleBillingNumberInput = (e) => {
        const { name, value } = e.target;
        const normalized = value.replace(',', '.');
        const pattern = name === 'pricePerStudentUsd' ? /^\d*\.?\d*$/ : /^\d*$/;
        if (!pattern.test(normalized)) return;

        setBillingFields((prev) => ({ ...prev, [name]: normalized }));

        if (normalized !== '' && !Number.isNaN(Number(normalized))) {
            const parsed = name === 'pricePerStudentUsd'
                ? Math.max(0, Number(normalized))
                : Math.max(0, Math.floor(Number(normalized)));
            setBillingData((prev) => ({ ...prev, [name]: parsed }));
        }
    };

    const handleBillingNumberBlur = (e) => {
        const { name } = e.target;
        const raw = billingFields[name].replace(',', '.');
        const defaults = { pricePerStudentUsd: 0, studentLimit: 80, driverLimit: 2 };
        let num;

        if (raw === '' || Number.isNaN(Number(raw))) {
            num = billingData[name] ?? defaults[name];
        } else if (name === 'pricePerStudentUsd') {
            num = Math.max(0, Number(raw));
        } else {
            num = Math.max(1, Math.floor(Number(raw)));
        }

        setBillingData((prev) => ({ ...prev, [name]: num }));
        setBillingFields((prev) => ({ ...prev, [name]: String(num) }));
    };

    const resolveBillingNumbers = () => ({
        pricePerStudentUsd: Math.max(0, Number(billingFields.pricePerStudentUsd.replace(',', '.')) || billingData.pricePerStudentUsd || 0),
        studentLimit: Math.max(1, Math.floor(Number(billingFields.studentLimit) || billingData.studentLimit || 80)),
        driverLimit: Math.max(1, Math.floor(Number(billingFields.driverLimit) || billingData.driverLimit || 2)),
    });

    const applyPlanPreset = (plan) => {
        const preset = PLAN_PRESETS[plan];
        if (!preset) return;
        setBillingData((prev) => ({ ...prev, plan, ...preset }));
        setBillingFields({
            pricePerStudentUsd: String(preset.pricePerStudentUsd),
            studentLimit: String(preset.studentLimit),
            driverLimit: String(preset.driverLimit),
        });
    };

    const handleBillingSave = async (e) => {
        e.preventDefault();
        setIsSaving(true);
        setErrorMsg('');
        const numbers = resolveBillingNumbers();
        try {
            const res = await authFetch('/api/companies', {
                method: 'PATCH',
                body: JSON.stringify({
                    unitCode: billingData.unitCode,
                    billing: {
                        plan: billingData.plan,
                        pricePerStudentUsd: numbers.pricePerStudentUsd,
                        status: billingData.status,
                        studentLimit: numbers.studentLimit,
                        driverLimit: numbers.driverLimit,
                    },
                }),
            });
            const data = await res.json();
            if (!res.ok) {
                setErrorMsg(data.error || 'No se pudo guardar la facturacion');
            } else {
                setShowBillingModal(false);
                toast.success('Facturacion actualizada');
                fetchCompanies();
            }
        } catch (err) {
            setErrorMsg('Error de red');
        } finally {
            setIsSaving(false);
        }
    };

    const openEditModal = (c) => {
        setEditData({
            unitCode: c.unitCode,
            companyName: c.name,
            transportCompany: c.transportCompany || '',
            adminName: c.adminName || 'Admin ' + c.unitCode,
            adminEmail: c.adminEmail || '',
            newPassword: '',
            schoolLat: c.schoolLat ?? null,
            schoolLng: c.schoolLng ?? null,
            schoolAddress: c.schoolAddress || '',
        });
        setEditTab('general');
        setShowEditModal(true);
        setDetailCompany(null);
        setSchoolUsersCompany(null);
        setErrorMsg('');
    };

    const openSchoolUsersModal = (c) => {
        setSchoolUsersCompany(c);
        setSchoolUserFormOpen(false);
        setSchoolUserForm({ name: '', email: '', password: '', role: 'viewer' });
        setDetailCompany(null);
        setShowEditModal(false);
        setErrorMsg('');
    };

    const handleCreateSchoolUser = async (e) => {
        e.preventDefault();
        if (!schoolUsersCompany) return;
        setSchoolUserSaving(true);
        setErrorMsg('');
        try {
            const res = await authFetch('/api/users/create', {
                method: 'POST',
                body: JSON.stringify({
                    ...schoolUserForm,
                    unitCode: schoolUsersCompany.unitCode,
                }),
            });
            const data = await res.json();
            if (!res.ok) {
                setErrorMsg(data.error || 'No se pudo crear el usuario');
                return;
            }
            toast.success('Usuario creado para el colegio');
            setSchoolUserFormOpen(false);
            setSchoolUserForm({ name: '', email: '', password: '', role: 'viewer' });
        } catch {
            setErrorMsg('Error de red al crear usuario');
        } finally {
            setSchoolUserSaving(false);
        }
    };

    const handleDeleteSchoolUser = async (user) => {
        if (!schoolUsersCompany) return;
        if (user.id === schoolUsersCompany.adminUid) {
            toast.error('No puedes eliminar al administrador principal. Usa Credenciales para cambiar su acceso.');
            return;
        }
        if (!window.confirm(`Eliminar acceso de ${user.name || user.email}?`)) return;
        try {
            const res = await authFetch('/api/users/create', {
                method: 'POST',
                body: JSON.stringify({ action: 'delete', uid: user.id, unitCode: schoolUsersCompany.unitCode }),
            });
            const data = await res.json();
            if (!res.ok) {
                toast.error(data.error || 'No se pudo eliminar');
                return;
            }
            toast.success('Usuario eliminado');
        } catch {
            toast.error('Error de red');
        }
    };

    const copyText = (text, label = 'Texto') => {
        if (typeof navigator !== 'undefined' && text) {
            navigator.clipboard.writeText(text);
            toast.success(`${label} copiado al portapapeles`);
        }
    };

    const parentShareMessage = (unitCode, schoolName) =>
        `Hola, bienvenido a RutaSegura.\n\n1) Descarga la app RutaSegura (padres).\n2) Ingresa el codigo de tu colegio: ${unitCode}${schoolName ? ` (${schoolName})` : ''}.\n3) Registra a tu hijo/a.\n4) El colegio aprobara la inscripcion y podras ver el recorrido en tiempo real.`;

    const handleEditChange = (e) => setEditData({ ...editData, [e.target.name]: e.target.value });

    const handleUpdate = async (e) => {
        e.preventDefault();
        setIsSaving(true);
        setErrorMsg('');

        try {
            const res = await authFetch('/api/companies', {
                method: 'PATCH',
                body: JSON.stringify(editData)
            });
            const data = await res.json();

            if (!res.ok) {
                setErrorMsg(data.error || 'Ocurrió un error al actualizar');
            } else {
                setShowEditModal(false);
                toast.success('Credenciales actualizadas');
                fetchCompanies();
            }
        } catch (err) {
            setErrorMsg('Error de red');
        } finally {
            setIsSaving(false);
        }
    };

    if (loading || profile?.role !== 'super_admin') return null;

    return (
        <DashboardLayout title="Instituciones — Super Admin">
            <div className="flex flex-wrap justify-between items-end gap-6 mb-8">
                <div>
                    <h2 className="text-4xl md:text-5xl font-black text-slate-900 font-headline tracking-tighter uppercase italic leading-none mb-3">
                        Centros educativos
                    </h2>
                    <p className="text-lg text-slate-500 font-bold">
                        Administra colegios, credenciales de acceso y métricas para facturación.
                    </p>
                </div>
                <button 
                    onClick={() => { setCreateStep('datos'); setErrorMsg(''); setShowModal(true); }}
                    className="bg-primary text-on-primary px-10 py-6 rounded-[2rem] font-black uppercase italic tracking-widest flex items-center gap-4 hover:scale-105 transition-all shadow-2xl shadow-blue-200"
                >
                    <span className="material-symbols-outlined text-3xl">add_business</span>
                    Crear Nuevo Colegio
                </button>
            </div>

            {adminWarning && (
                <div className="mb-6 p-4 rounded-2xl bg-amber-50 border border-amber-200 text-amber-900 text-sm font-bold">
                    {adminWarning}
                </div>
            )}

            <SchoolOnboardingGuide />
            <div className="h-6" />

            {loadError && (
                <div className="mb-6 p-4 rounded-2xl bg-rose-50 border border-rose-200 text-rose-800 text-sm font-bold">
                    {loadError}
                    <button type="button" onClick={fetchCompanies} className="ml-4 underline">Reintentar</button>
                </div>
            )}

            {totals && (
                <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-8">
                    {[
                        { label: 'Colegios', value: totals.companies },
                        { label: 'Conductores', value: totals.drivers },
                        { label: 'Estudiantes', value: totals.students },
                        { label: 'Activos', value: totals.studentsActive },
                        { label: 'Facturacion (USD)', value: `$${totals.monthlyRecurringUsd ?? 0}` },
                    ].map((t) => (
                        <div key={t.label} className="bg-white rounded-2xl p-5 border border-slate-100 shadow-sm">
                            <p className="text-2xl font-black text-primary">{t.value}</p>
                            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{t.label}</p>
                        </div>
                    ))}
                </div>
            )}

            {fetching ? (
                <div className="mt-10 text-center text-slate-400 font-bold animate-pulse">Cargando base de datos global...</div>
            ) : (
                <ResponsiveTable className="bg-surface-container-lowest border-outline-variant/10 shadow-sm">
                    <table className="w-full text-left border-collapse table-fixed">
                        <thead>
                            <tr className="bg-slate-50 border-b border-slate-100">
                                <th className="w-[72px] px-3 py-3 text-[10px] font-bold text-slate-400 uppercase tracking-wide">Código</th>
                                <th className="px-3 py-3 text-[10px] font-bold text-slate-400 uppercase tracking-wide">Institución</th>
                                <th className="hidden lg:table-cell w-[100px] px-3 py-3 text-[10px] font-bold text-slate-400 uppercase tracking-wide text-center">Ubicación</th>
                                <th className="hidden md:table-cell px-3 py-3 text-[10px] font-bold text-slate-400 uppercase tracking-wide">Administrador</th>
                                <th className="w-16 px-2 py-3 text-[10px] font-bold text-slate-400 uppercase tracking-wide text-center">Cond.</th>
                                <th className="w-16 px-2 py-3 text-[10px] font-bold text-slate-400 uppercase tracking-wide text-center">Est.</th>
                                <th className="hidden sm:table-cell w-[120px] px-3 py-3 text-[10px] font-bold text-slate-400 uppercase tracking-wide text-center">Facturación</th>
                                <th className="w-12 px-2 py-3"></th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-50">
                            {companies.map((c) => (
                                    <tr key={c.unitCode} className="hover:bg-slate-50/80 transition-colors">
                                        <td className="px-3 py-4">
                                            <span className="inline-block font-bold text-sm text-primary bg-violet-50 px-2 py-1 rounded-lg">{c.unitCode}</span>
                                        </td>
                                        <td className="px-3 py-4 min-w-0">
                                            <p className="font-semibold text-sm text-slate-800 truncate">{c.name}</p>
                                            <div className="flex flex-wrap items-center gap-2 mt-1">
                                                <span className="text-[10px] text-slate-400 font-medium uppercase">{c.status || 'active'}</span>
                                                {!c.hasSchoolLocation && (
                                                    <span className="lg:hidden inline-flex items-center gap-0.5 text-[10px] font-semibold text-amber-600">
                                                        <span className="material-symbols-outlined text-xs">warning</span>
                                                        Sin pin
                                                    </span>
                                                )}
                                            </div>
                                        </td>
                                        <td className="hidden lg:table-cell px-3 py-4 text-center">
                                            {c.hasSchoolLocation ? (
                                              <span className="inline-flex items-center gap-1 bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded-full text-[10px] font-semibold">
                                                <span className="material-symbols-outlined text-xs">location_on</span>
                                                OK
                                              </span>
                                            ) : (
                                              <span className="inline-flex items-center gap-1 bg-amber-50 text-amber-700 px-2 py-0.5 rounded-full text-[10px] font-semibold">
                                                <span className="material-symbols-outlined text-xs">warning</span>
                                                Sin pin
                                              </span>
                                            )}
                                        </td>
                                        <td className="hidden md:table-cell px-3 py-4 min-w-0">
                                            <p className="text-sm font-medium text-slate-700 truncate">{c.adminName || '—'}</p>
                                            <p className="text-xs text-slate-400 truncate">{c.adminEmail || '—'}</p>
                                        </td>
                                        <td className="px-2 py-4 text-center text-sm font-semibold text-slate-700">{c.driversCount}</td>
                                        <td className="px-2 py-4 text-center text-sm font-semibold text-slate-700">{c.studentsTotal}</td>
                                        <td className="hidden sm:table-cell px-3 py-4">
                                            <div className="flex flex-col items-center gap-0.5">
                                                <BillingStatusBadge status={c.billingStatus || 'active'} />
                                                <span className="text-[10px] font-medium text-slate-500">
                                                    ${c.pricePerStudentUsd ?? 0}/est · {c.studentsActive ?? 0} act.
                                                </span>
                                                <span className="text-[10px] font-black text-violet-700">
                                                    ${c.monthlyChargeUsd ?? 0}/mes
                                                </span>
                                                <span className={`text-[10px] font-medium ${
                                                    usageTone(c.driversCount, c.driverLimit) === 'danger' ? 'text-rose-600'
                                                    : usageTone(c.driversCount, c.driverLimit) === 'warning' ? 'text-amber-600'
                                                    : 'text-slate-400'
                                                }`}>
                                                    {c.driversCount}/{c.driverLimit ?? 2} cond.
                                                </span>
                                            </div>
                                        </td>
                                        <td className="px-2 py-4 text-right">
                                            <CompanyActionsMenu
                                                company={c}
                                                onEnter={enterAsSchool}
                                                onDetail={setDetailCompany}
                                                onBilling={openBillingModal}
                                                onCredentials={openEditModal}
                                                onUsers={openSchoolUsersModal}
                                                onDelete={(co) => setConfirmingDelete(co.unitCode)}
                                            />
                                        </td>
                                    </tr>
                            ))}
                            {companies.length === 0 && !loadError && (
                                <tr><td colSpan="8" className="text-center py-10 text-slate-400">No hay instituciones registradas aún.</td></tr>
                            )}
                            {companies.length === 0 && loadError && (
                                <tr><td colSpan="8" className="text-center py-10 text-slate-400">No se pudo cargar el listado. Ver mensaje arriba.</td></tr>
                            )}
                        </tbody>
                    </table>
                </ResponsiveTable>
            )}

            {/* DETALLE INSTITUCIÓN */}
            <Modal
                open={!!detailCompany}
                onClose={() => setDetailCompany(null)}
                title={detailCompany?.name}
                subtitle={`Código: ${detailCompany?.unitCode}`}
                icon="school"
                accent="border-primary"
                footer={
                    <div className="flex flex-wrap gap-3">
                        <button
                            type="button"
                            onClick={() => detailCompany && openSchoolUsersModal(detailCompany)}
                            className="flex-1 min-w-[140px] py-2.5 rounded-xl border border-sky-200 text-sky-700 font-semibold text-sm hover:bg-sky-50 transition-colors flex items-center justify-center gap-1.5"
                        >
                            <span className="material-symbols-outlined text-base">group</span>
                            Usuarios
                        </button>
                        <button
                            type="button"
                            onClick={() => detailCompany && openEditModal(detailCompany)}
                            className="flex-1 min-w-[140px] bg-primary text-white py-2.5 rounded-xl font-semibold text-sm hover:bg-primary/90 transition-colors"
                        >
                            Restablecer clave
                        </button>
                        <button
                            type="button"
                            onClick={() => setDetailCompany(null)}
                            className="px-5 py-2.5 rounded-xl border border-slate-200 font-medium text-sm text-slate-600 hover:bg-white transition-colors"
                        >
                            Cerrar
                        </button>
                    </div>
                }
            >
                {detailCompany && (
                    <div className="space-y-4">
                        <div className="p-4 bg-violet-50 rounded-xl border border-violet-100">
                            <div className="flex items-center justify-between gap-3 mb-2">
                                <p className="text-xs font-semibold text-violet-700 uppercase tracking-wide">Código para padres (app)</p>
                                <button
                                    type="button"
                                    onClick={() => copyText(detailCompany.unitCode, 'Código')}
                                    className="text-xs font-semibold text-primary hover:underline flex items-center gap-1"
                                >
                                    <span className="material-symbols-outlined text-sm">content_copy</span>
                                    Copiar
                                </button>
                            </div>
                            <p className="font-bold text-2xl text-primary tracking-wide">{detailCompany.unitCode}</p>
                            <p className="text-xs text-slate-600 mt-2 leading-relaxed">
                                Los padres ingresan este código en la app para vincular el colegio e inscribir alumnos.
                            </p>
                            <button
                                type="button"
                                onClick={() => copyText(parentShareMessage(detailCompany.unitCode, detailCompany.name), 'Mensaje para padres')}
                                className="mt-3 w-full py-2 rounded-lg border border-violet-200 text-violet-700 text-xs font-semibold hover:bg-violet-100/50 transition-colors flex items-center justify-center gap-1.5"
                            >
                                <span className="material-symbols-outlined text-sm">chat</span>
                                Copiar mensaje para WhatsApp
                            </button>
                        </div>

                        <div className="p-4 bg-slate-50 rounded-xl border border-slate-100">
                            <div className="flex items-center justify-between gap-3 mb-1">
                                <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Correo del administrador (panel web)</p>
                                {detailCompany.adminEmail && (
                                    <button
                                        type="button"
                                        onClick={() => copyText(detailCompany.adminEmail, 'Correo admin')}
                                        className="text-xs font-semibold text-primary hover:underline"
                                    >
                                        Copiar
                                    </button>
                                )}
                            </div>
                            <p className="font-medium text-slate-800 break-all">{detailCompany.adminEmail || 'No registrado'}</p>
                        </div>

                        <div className="grid grid-cols-3 gap-3">
                            <div className="p-3 bg-emerald-50 rounded-xl text-center border border-emerald-100">
                                <p className="text-xl font-bold text-emerald-700">{detailCompany.driversCount}</p>
                                <p className="text-[10px] font-semibold text-emerald-600 uppercase mt-0.5">Conductores</p>
                            </div>
                            <div className="p-3 bg-blue-50 rounded-xl text-center border border-blue-100">
                                <p className="text-xl font-bold text-blue-700">{detailCompany.studentsTotal}</p>
                                <p className="text-[10px] font-semibold text-blue-600 uppercase mt-0.5">Estudiantes</p>
                            </div>
                            <div className="p-3 bg-amber-50 rounded-xl text-center border border-amber-100">
                                <p className="text-xl font-bold text-amber-700">{detailCompany.studentsPending}</p>
                                <p className="text-[10px] font-semibold text-amber-600 uppercase mt-0.5">Pendientes</p>
                            </div>
                        </div>

                        <p className="text-xs text-slate-500 leading-relaxed">
                            Conductores, rutas e inscripciones los gestiona el administrador del colegio desde su panel.
                        </p>
                    </div>
                )}
            </Modal>

            {/* USUARIOS DEL COLEGIO */}
            <Modal
                open={!!schoolUsersCompany}
                onClose={() => { setSchoolUsersCompany(null); setSchoolUserFormOpen(false); setErrorMsg(''); }}
                title={`Usuarios — ${schoolUsersCompany?.name || ''}`}
                subtitle={schoolUsersCompany ? `Codigo: ${schoolUsersCompany.unitCode}` : undefined}
                icon="group"
                accent="border-sky-500"
                size="lg"
                footer={
                    <button
                        type="button"
                        onClick={() => { setSchoolUsersCompany(null); setSchoolUserFormOpen(false); setErrorMsg(''); }}
                        className="w-full py-2.5 rounded-xl border border-slate-200 font-medium text-sm text-slate-600 hover:bg-white transition-colors"
                    >
                        Cerrar
                    </button>
                }
            >
                {schoolUsersCompany && (
                    <div className="space-y-4">
                        <div className="flex items-center justify-between gap-3">
                            <p className="text-xs text-slate-500">
                                Cuentas con acceso al panel web de este colegio.
                            </p>
                            <button
                                type="button"
                                onClick={() => setSchoolUserFormOpen((v) => !v)}
                                className="shrink-0 flex items-center gap-1.5 px-3 py-2 rounded-xl bg-sky-600 text-white text-xs font-semibold hover:bg-sky-700 transition-colors"
                            >
                                <span className="material-symbols-outlined text-base">{schoolUserFormOpen ? 'close' : 'person_add'}</span>
                                {schoolUserFormOpen ? 'Cancelar' : 'Crear usuario'}
                            </button>
                        </div>

                        {errorMsg && schoolUserFormOpen && (
                            <div className="bg-error-container/20 text-error text-xs font-medium p-3 rounded-xl border border-error/10">
                                {errorMsg}
                            </div>
                        )}

                        {schoolUserFormOpen && (
                            <form id="school-user-form" onSubmit={handleCreateSchoolUser} className="p-4 rounded-xl border border-sky-100 bg-sky-50/50 space-y-3">
                                <p className="text-xs font-semibold text-sky-800">Nuevo acceso para {schoolUsersCompany.unitCode}</p>
                                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                    <div className="space-y-1">
                                        <label className="text-xs font-semibold text-slate-500">Nombre</label>
                                        <input
                                            required
                                            type="text"
                                            value={schoolUserForm.name}
                                            onChange={(e) => setSchoolUserForm((p) => ({ ...p, name: e.target.value }))}
                                            placeholder="Ej. Monitor de rutas"
                                            className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm outline-none focus:ring-2 focus:ring-sky-200"
                                        />
                                    </div>
                                    <div className="space-y-1">
                                        <label className="text-xs font-semibold text-slate-500">Rol</label>
                                        <select
                                            value={schoolUserForm.role}
                                            onChange={(e) => setSchoolUserForm((p) => ({ ...p, role: e.target.value }))}
                                            className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm outline-none focus:ring-2 focus:ring-sky-200"
                                        >
                                            <option value="viewer">Solo lectura</option>
                                            <option value="admin">Administrador</option>
                                        </select>
                                    </div>
                                </div>
                                <div className="space-y-1">
                                    <label className="text-xs font-semibold text-slate-500">Correo</label>
                                    <input
                                        required
                                        type="email"
                                        value={schoolUserForm.email}
                                        onChange={(e) => setSchoolUserForm((p) => ({ ...p, email: e.target.value }))}
                                        placeholder="usuario@colegio.com"
                                        className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm outline-none focus:ring-2 focus:ring-sky-200"
                                    />
                                </div>
                                <div className="space-y-1">
                                    <label className="text-xs font-semibold text-slate-500">Contrasena (min. 8 caracteres)</label>
                                    <input
                                        required
                                        type="text"
                                        minLength={8}
                                        value={schoolUserForm.password}
                                        onChange={(e) => setSchoolUserForm((p) => ({ ...p, password: e.target.value }))}
                                        placeholder="Contrasena de acceso"
                                        className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm outline-none focus:ring-2 focus:ring-sky-200"
                                    />
                                </div>
                                <button
                                    type="submit"
                                    disabled={schoolUserSaving}
                                    className="w-full py-2.5 rounded-xl bg-sky-600 text-white text-sm font-semibold hover:bg-sky-700 disabled:opacity-50 transition-colors"
                                >
                                    {schoolUserSaving ? 'Creando...' : 'Crear acceso'}
                                </button>
                            </form>
                        )}

                        <div className="rounded-xl border border-slate-200 overflow-hidden">
                            {schoolUsers.length === 0 ? (
                                <p className="p-6 text-center text-sm text-slate-400">No hay usuarios adicionales para este colegio.</p>
                            ) : (
                                <ul className="divide-y divide-slate-100">
                                    {schoolUsers.map((user) => {
                                        const isPrimary = user.id === schoolUsersCompany.adminUid;
                                        return (
                                            <li key={user.id} className="flex items-center gap-3 p-3 hover:bg-slate-50/80">
                                                <div className="w-9 h-9 rounded-full bg-sky-100 text-sky-700 flex items-center justify-center font-bold text-sm uppercase shrink-0">
                                                    {user.name?.charAt(0) || '?'}
                                                </div>
                                                <div className="flex-1 min-w-0">
                                                    <div className="flex flex-wrap items-center gap-2">
                                                        <p className="text-sm font-semibold text-slate-800 truncate">{user.name}</p>
                                                        {isPrimary && (
                                                            <span className="text-[10px] font-semibold uppercase px-2 py-0.5 rounded-full bg-violet-100 text-violet-700">
                                                                Admin principal
                                                            </span>
                                                        )}
                                                    </div>
                                                    <p className="text-xs text-slate-500 truncate">{user.email}</p>
                                                </div>
                                                <span className={`text-[10px] font-semibold px-2 py-1 rounded-full uppercase shrink-0 ${
                                                    user.role === 'admin' ? 'bg-emerald-100 text-emerald-700' : 'bg-blue-100 text-blue-700'
                                                }`}>
                                                    {user.role === 'admin' ? 'Admin' : 'Lectura'}
                                                </span>
                                                {!isPrimary && (
                                                    <button
                                                        type="button"
                                                        onClick={() => handleDeleteSchoolUser(user)}
                                                        className="p-2 text-rose-500 hover:bg-rose-50 rounded-lg transition-colors shrink-0"
                                                        aria-label="Eliminar usuario"
                                                    >
                                                        <span className="material-symbols-outlined text-lg">delete</span>
                                                    </button>
                                                )}
                                            </li>
                                        );
                                    })}
                                </ul>
                            )}
                        </div>
                    </div>
                )}
            </Modal>

            {/* MODAL DE CREACIÓN */}
            {showModal && (
                <div className="fixed inset-0 z-[1000] bg-black/40 backdrop-blur-sm flex items-center justify-center p-4">
                    <div className="bg-white rounded-2xl max-w-lg w-full shadow-2xl relative flex flex-col max-h-[90vh]">
                        <div className="flex-shrink-0 px-6 pt-6 pb-4 border-b border-slate-100">
                            <button onClick={() => { setShowModal(false); setCreateStep('datos'); setErrorMsg(''); }} className="absolute top-4 right-4 p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100">
                                <span className="material-symbols-outlined">close</span>
                            </button>
                            <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2 pr-10">
                                <span className="material-symbols-outlined text-primary">domain_add</span>
                                Registrar colegio
                            </h3>
                            <div className="flex gap-1 p-1 bg-slate-100 rounded-xl mt-4">
                                {[
                                    { id: 'datos', label: '1. Datos', icon: 'business' },
                                    { id: 'ubicacion', label: '2. Ubicacion', icon: 'location_on' },
                                    { id: 'credenciales', label: '3. Admin', icon: 'admin_panel_settings' },
                                ].map((step) => (
                                    <button
                                        key={step.id}
                                        type="button"
                                        onClick={() => setCreateStep(step.id)}
                                        className={`flex-1 flex items-center justify-center gap-1 py-2 px-2 rounded-lg text-[11px] font-semibold transition-colors ${
                                            createStep === step.id ? 'bg-white text-primary shadow-sm' : 'text-slate-500 hover:text-slate-700'
                                        }`}
                                    >
                                        <span className="material-symbols-outlined text-sm hidden sm:inline">{step.icon}</span>
                                        {step.label}
                                    </button>
                                ))}
                            </div>
                        </div>

                        <div className="flex-1 overflow-y-auto px-6 py-5 min-h-0">
                            {errorMsg && (
                                <div className="mb-4 bg-error-container/20 text-error text-xs font-medium p-3 rounded-xl border border-error/10">
                                    {errorMsg}
                                </div>
                            )}

                            <form id="create-company-form" onSubmit={handleCreate} className="space-y-4">
                            {createStep === 'datos' && (
                                <>
                                    <p className="text-xs text-slate-500">Define el codigo que usaran los padres en la app y el nombre del colegio.</p>
                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="space-y-1">
                                            <label className="text-xs font-semibold text-slate-500">Codigo unico</label>
                                            <input required name="unitCode" value={formData.unitCode} onChange={handleChange} placeholder="Ej. CAD32" className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm font-bold text-primary focus:ring-2 focus:ring-primary/20 outline-none uppercase" />
                                        </div>
                                        <div className="space-y-1">
                                            <label className="text-xs font-semibold text-slate-500">Nombre institucion</label>
                                            <input required name="companyName" value={formData.companyName} onChange={handleChange} placeholder="Ej. Colegio San Jose" className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 outline-none" />
                                        </div>
                                    </div>
                                    <div className="space-y-1">
                                        <label className="text-xs font-semibold text-slate-500">Compania de transporte (opcional)</label>
                                        <input
                                            name="transportCompany"
                                            value={formData.transportCompany}
                                            onChange={handleChange}
                                            placeholder="Ej. Transportes del Norte, Otavalo"
                                            className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 outline-none"
                                        />
                                    </div>
                                </>
                            )}

                            {createStep === 'ubicacion' && (
                                <>
                                    <p className="text-xs text-slate-500 mb-2">Busca por direccion, nombre del colegio o coordenadas GPS (lat, lng). Tambien puedes hacer clic en el mapa o arrastrar el pin.</p>
                                    <CompanyLocationPicker
                                        lat={formData.schoolLat}
                                        lng={formData.schoolLng}
                                        schoolName={formData.companyName}
                                        address={formData.schoolAddress}
                                        onChange={(lat, lng) => setFormData((prev) => ({ ...prev, schoolLat: lat, schoolLng: lng }))}
                                        onAddressChange={(addr) => setFormData((prev) => ({ ...prev, schoolAddress: addr }))}
                                    />
                                    <div className="space-y-1">
                                        <label className="text-xs font-semibold text-slate-500">Direccion (editable)</label>
                                        <input
                                            name="schoolAddress"
                                            value={formData.schoolAddress}
                                            onChange={handleChange}
                                            placeholder="Se completa al buscar o marcar en el mapa"
                                            className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 outline-none"
                                        />
                                    </div>
                                </>
                            )}

                            {createStep === 'credenciales' && (
                                <>
                                    <p className="text-xs text-slate-500">Estas credenciales permiten al colegio acceder a su panel web.</p>
                                    <div className="space-y-3">
                                        <div className="space-y-1">
                                            <label className="text-xs font-semibold text-slate-500">Nombre del admin</label>
                                            <input required name="adminName" value={formData.adminName} onChange={handleChange} className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 outline-none" />
                                        </div>
                                        <div className="space-y-1">
                                            <label className="text-xs font-semibold text-slate-500">Correo electronico</label>
                                            <input required type="email" name="adminEmail" value={formData.adminEmail} onChange={handleChange} className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 outline-none" />
                                        </div>
                                        <div className="space-y-1">
                                            <label className="text-xs font-semibold text-slate-500">Contrasena asignada</label>
                                            <input required type="text" name="adminPassword" value={formData.adminPassword} onChange={handleChange} className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 outline-none" />
                                        </div>
                                    </div>
                                </>
                            )}

                            </form>
                        </div>

                        <div className="flex-shrink-0 px-6 py-4 border-t border-slate-100 bg-slate-50/50 rounded-b-2xl flex gap-3">
                            {createStep !== 'datos' && (
                                <button
                                    type="button"
                                    onClick={() => setCreateStep(createStep === 'credenciales' ? 'ubicacion' : 'datos')}
                                    className="px-5 py-2.5 rounded-xl border border-slate-200 font-medium text-sm text-slate-600 hover:bg-white transition-colors"
                                >
                                    Anterior
                                </button>
                            )}
                            {createStep === 'datos' && (
                                <button
                                    type="button"
                                    onClick={() => {
                                        setErrorMsg('');
                                        if (!formData.unitCode.trim() || !formData.companyName.trim()) {
                                            setErrorMsg('Completa el codigo y el nombre del colegio.');
                                            return;
                                        }
                                        setCreateStep('ubicacion');
                                    }}
                                    className="flex-1 bg-primary text-white py-2.5 rounded-xl font-semibold text-sm hover:bg-primary/90 transition-colors"
                                >
                                    Siguiente: Ubicacion
                                </button>
                            )}
                            {createStep === 'ubicacion' && (
                                <button
                                    type="button"
                                    onClick={() => {
                                        setErrorMsg('');
                                        if (formData.schoolLat == null || formData.schoolLng == null) {
                                            setErrorMsg('Marca la ubicacion del colegio buscando o haciendo clic en el mapa.');
                                            return;
                                        }
                                        setCreateStep('credenciales');
                                    }}
                                    className="flex-1 bg-primary text-white py-2.5 rounded-xl font-semibold text-sm hover:bg-primary/90 transition-colors"
                                >
                                    Siguiente: Credenciales
                                </button>
                            )}
                            {createStep === 'credenciales' && (
                                <button type="submit" form="create-company-form" disabled={isSaving} className="flex-1 bg-primary text-white py-2.5 rounded-xl font-semibold text-sm hover:bg-primary/90 transition-all flex justify-center items-center">
                                    {isSaving ? <div className="animate-spin w-5 h-5 border-2 border-white/30 border-t-white rounded-full"></div> : 'Generar sistema y credenciales'}
                                </button>
                            )}
                        </div>
                    </div>
                </div>
            )}

            {/* MODAL DE EDICIÓN Y RESET DE CLAVE */}
            <Modal
                open={showEditModal}
                onClose={() => setShowEditModal(false)}
                title="Credenciales del administrador"
                subtitle={editData.unitCode ? `Colegio: ${editData.companyName} (${editData.unitCode})` : undefined}
                icon="lock_reset"
                accent="border-secondary"
                size="lg"
                footer={
                    <button
                        type="submit"
                        form="edit-company-form"
                        disabled={isSaving}
                        className="w-full bg-secondary text-white py-2.5 rounded-xl font-semibold text-sm hover:bg-secondary/90 transition-colors flex justify-center items-center"
                    >
                        {isSaving ? (
                            <div className="animate-spin w-5 h-5 border-2 border-white/30 border-t-white rounded-full" />
                        ) : (
                            'Guardar cambios'
                        )}
                    </button>
                }
            >
                {errorMsg && (
                    <div className="mb-4 bg-error-container/20 text-error text-xs font-medium p-3 rounded-xl border border-error/10">
                        {errorMsg}
                    </div>
                )}

                <div className="flex gap-1 p-1 bg-slate-100 rounded-xl mb-5">
                    {[
                        { id: 'general', label: 'Datos', icon: 'business' },
                        { id: 'location', label: 'Ubicación', icon: 'location_on' },
                        { id: 'security', label: 'Contraseña', icon: 'key' },
                    ].map((tab) => (
                        <button
                            key={tab.id}
                            type="button"
                            onClick={() => setEditTab(tab.id)}
                            className={`flex-1 flex items-center justify-center gap-1.5 py-2 px-3 rounded-lg text-xs font-semibold transition-colors ${
                                editTab === tab.id
                                    ? 'bg-white text-primary shadow-sm'
                                    : 'text-slate-500 hover:text-slate-700'
                            }`}
                        >
                            <span className="material-symbols-outlined text-base">{tab.icon}</span>
                            {tab.label}
                        </button>
                    ))}
                </div>

                <form id="edit-company-form" onSubmit={handleUpdate} className="space-y-4">
                    {editTab === 'general' && (
                        <>
                            <div className="space-y-1">
                                <label className="text-xs font-semibold text-slate-500">Código único</label>
                                <input readOnly value={editData.unitCode} className="w-full p-2.5 bg-slate-100 border border-slate-200 rounded-lg text-sm font-medium text-slate-500 cursor-not-allowed" />
                            </div>
                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                <div className="space-y-1">
                                    <label className="text-xs font-semibold text-slate-500">Institución</label>
                                    <input name="companyName" value={editData.companyName} onChange={handleEditChange} className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-secondary/20 outline-none" />
                                </div>
                                <div className="space-y-1">
                                    <label className="text-xs font-semibold text-slate-500">Nombre del admin</label>
                                    <input name="adminName" value={editData.adminName} onChange={handleEditChange} className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-secondary/20 outline-none" />
                                </div>
                            </div>
                            <div className="space-y-1">
                                <label className="text-xs font-semibold text-slate-500">Correo de acceso (no editable)</label>
                                <input readOnly value={editData.adminEmail || 'No registrado'} className="w-full p-2.5 bg-slate-100 border border-slate-200 rounded-lg text-sm text-slate-600 cursor-not-allowed" />
                            </div>
                            <div className="space-y-1">
                                <label className="text-xs font-semibold text-slate-500">Compañía de transporte / Cooperativa</label>
                                <input
                                    name="transportCompany"
                                    value={editData.transportCompany}
                                    onChange={handleEditChange}
                                    placeholder="Cooperativa asignada a esta sede"
                                    className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-secondary/20 outline-none"
                                />
                            </div>
                        </>
                    )}

                    {editTab === 'location' && (
                        <div className="relative z-0">
                            <CompanyLocationPicker
                                lat={editData.schoolLat}
                                lng={editData.schoolLng}
                                schoolName={editData.companyName}
                                address={editData.schoolAddress}
                                onChange={(lat, lng) => setEditData((prev) => ({ ...prev, schoolLat: lat, schoolLng: lng }))}
                                onAddressChange={(addr) => setEditData((prev) => ({ ...prev, schoolAddress: addr }))}
                            />
                            <div className="space-y-1 mt-4">
                                <label className="text-xs font-semibold text-slate-500">Direccion (editable)</label>
                                <input
                                    name="schoolAddress"
                                    value={editData.schoolAddress}
                                    onChange={handleEditChange}
                                    placeholder="Ej. Av. Principal y Calle 10"
                                    className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-secondary/20 outline-none"
                                />
                            </div>
                        </div>
                    )}

                    {editTab === 'security' && (
                        <div className="p-4 bg-amber-50 rounded-xl border border-amber-100">
                            <div className="flex items-center gap-2 mb-2 text-amber-800">
                                <span className="material-symbols-outlined text-lg">lock_reset</span>
                                <h4 className="text-sm font-semibold">Restablecer contraseña</h4>
                            </div>
                            <p className="text-xs text-slate-600 mb-3 leading-relaxed">
                                Si el administrador olvidó su acceso, escribe una nueva clave. Si la dejas en blanco, no se modificará.
                            </p>
                            <input
                                type="text"
                                name="newPassword"
                                value={editData.newPassword}
                                onChange={handleEditChange}
                                placeholder="Nueva contraseña (opcional)"
                                className="w-full p-2.5 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-amber-300 outline-none placeholder:text-slate-400"
                            />
                        </div>
                    )}
                </form>
            </Modal>

            {/* MODAL ÉXITO — COLEGIO CREADO */}
            {createdSchool && (
                <div className="fixed inset-0 z-[1100] bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
                    <div className="bg-white rounded-3xl p-8 max-w-lg w-full shadow-2xl border-t-4 border-emerald-500">
                        <div className="flex items-center gap-3 mb-4">
                            <span className="material-symbols-outlined text-3xl text-emerald-600">check_circle</span>
                            <h3 className="text-xl font-black text-slate-900">Colegio creado correctamente</h3>
                        </div>
                        <p className="text-sm text-slate-600 mb-6">
                            <strong>{createdSchool.companyName}</strong> ya esta en el sistema. Sigue estos pasos para activar el flujo completo.
                        </p>

                        <div className="space-y-3 mb-6">
                            <div className="p-4 rounded-2xl bg-violet-50 border border-violet-100">
                                <p className="text-[10px] font-black uppercase text-violet-700 tracking-widest mb-1">Para padres (app)</p>
                                <p className="text-3xl font-black text-primary">{createdSchool.unitCode}</p>
                                <button type="button" onClick={() => copyText(createdSchool.unitCode, 'Codigo')} className="mt-2 text-xs font-black text-primary uppercase">Copiar codigo</button>
                            </div>
                            <div className="p-4 rounded-2xl bg-slate-50 border border-slate-100">
                                <p className="text-[10px] font-black uppercase text-slate-500 tracking-widest mb-1">Para administrador (panel web)</p>
                                <p className="text-sm font-bold text-slate-800">{createdSchool.adminEmail}</p>
                                <p className="text-sm font-bold text-slate-600 mt-1">Clave: {createdSchool.adminPassword}</p>
                                <button
                                    type="button"
                                    onClick={() => copyText(`Correo: ${createdSchool.adminEmail}\nClave: ${createdSchool.adminPassword}`, 'Credenciales admin')}
                                    className="mt-2 text-xs font-black text-primary uppercase"
                                >
                                    Copiar credenciales
                                </button>
                            </div>
                        </div>

                        <button
                            type="button"
                            onClick={() => copyText(parentShareMessage(createdSchool.unitCode, createdSchool.companyName), 'Mensaje para padres')}
                            className="w-full mb-3 py-3 rounded-xl border border-violet-200 text-violet-700 font-black text-[10px] uppercase tracking-widest hover:bg-violet-50"
                        >
                            Copiar mensaje para padres (WhatsApp)
                        </button>
                        <button
                            type="button"
                            onClick={() => setCreatedSchool(null)}
                            className="w-full py-4 rounded-xl bg-primary text-white font-bold"
                        >
                            Entendido
                        </button>
                    </div>
                </div>
            )}

            {/* MODAL DE FACTURACION */}
            {showBillingModal && (
                <div className="fixed inset-0 z-[1000] bg-black/40 backdrop-blur-sm flex items-center justify-center p-4">
                    <div className="bg-white rounded-3xl p-8 max-w-lg w-full shadow-2xl relative border-t-4 border-violet-500">
                        <button onClick={() => setShowBillingModal(false)} className="absolute top-6 right-6 text-slate-400 hover:text-error">
                            <span className="material-symbols-outlined">close</span>
                        </button>

                        <h3 className="text-xl font-black text-violet-700 font-headline tracking-tighter uppercase mb-2 flex items-center gap-2">
                            <span className="material-symbols-outlined">payments</span>
                            Facturacion — {billingData.companyName}
                        </h3>
                        <p className="text-xs text-slate-500 font-bold mb-2">Codigo: {billingData.unitCode}</p>
                        <p className="text-[11px] text-slate-600 mb-6 leading-relaxed">
                            Cobro mensual = <strong>estudiantes activos</strong> × <strong>precio por estudiante</strong>.
                            Los pendientes de aprobacion no cuentan hasta activarse.
                        </p>

                        {errorMsg && (
                            <div className="mb-6 bg-error-container/20 text-error text-xs font-bold p-3 rounded-xl border border-error/10">
                                {errorMsg}
                            </div>
                        )}

                        <form onSubmit={handleBillingSave} className="space-y-4">
                            <div className="flex flex-wrap gap-2">
                                {Object.keys(PLAN_PRESETS).map((plan) => (
                                    <button
                                        key={plan}
                                        type="button"
                                        onClick={() => applyPlanPreset(plan)}
                                        className={`px-3 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest border ${
                                            billingData.plan === plan
                                                ? 'bg-violet-600 text-white border-violet-600'
                                                : 'bg-slate-50 text-slate-600 border-slate-200'
                                        }`}
                                    >
                                        {plan}
                                    </button>
                                ))}
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div className="space-y-1">
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Plan</label>
                                    <select name="plan" value={billingData.plan} onChange={handleBillingChange} className="w-full p-3 bg-slate-50 border-none rounded-xl text-sm font-bold">
                                        <option value="basic">Basic</option>
                                        <option value="standard">Standard</option>
                                        <option value="premium">Premium</option>
                                    </select>
                                </div>
                                <div className="space-y-1">
                                    <label className="text-[10px] font-black text-slate-500 uppercase tracking-widest">Estado</label>
                                    <select name="status" value={billingData.status} onChange={handleBillingChange} className="w-full p-3 bg-slate-50 border-none rounded-xl text-sm font-bold">
                                        <option value="active">Activo</option>
                                        <option value="trial">Prueba</option>
                                        <option value="suspended">Suspendido</option>
                                        <option value="cancelled">Cancelado</option>
                                    </select>
                                </div>
                            </div>

                            <div className="p-4 rounded-2xl bg-violet-50 border border-violet-100">
                                <div className="flex flex-wrap items-end justify-between gap-3">
                                    <div>
                                        <p className="text-[10px] font-black uppercase text-violet-700 tracking-widest">Estudiantes activos</p>
                                        <p className="text-3xl font-black text-slate-900">{billingData.studentsActive}</p>
                                    </div>
                                    <div className="text-right">
                                        <p className="text-[10px] font-black uppercase text-violet-700 tracking-widest">Total a cobrar / mes</p>
                                        <p className="text-3xl font-black text-primary">${billingPreviewTotal}</p>
                                    </div>
                                </div>
                                <p className="text-[11px] text-slate-600 mt-3">
                                    {billingData.studentsActive} estudiante{billingData.studentsActive === 1 ? '' : 's'} × ${billingData.pricePerStudentUsd} = ${billingPreviewTotal} USD
                                </p>
                            </div>

                            <div className="grid grid-cols-3 gap-4">
                                <BillingNumberField
                                    label="USD / estudiante / mes"
                                    name="pricePerStudentUsd"
                                    value={billingFields.pricePerStudentUsd}
                                    onChange={handleBillingNumberInput}
                                    onBlur={handleBillingNumberBlur}
                                    placeholder="Ej. 0.9"
                                    inputMode="decimal"
                                />
                                <BillingNumberField
                                    label="Max. estudiantes"
                                    name="studentLimit"
                                    value={billingFields.studentLimit}
                                    onChange={handleBillingNumberInput}
                                    onBlur={handleBillingNumberBlur}
                                    placeholder="Ej. 80"
                                />
                                <BillingNumberField
                                    label="Max. conductores"
                                    name="driverLimit"
                                    value={billingFields.driverLimit}
                                    onChange={handleBillingNumberInput}
                                    onBlur={handleBillingNumberBlur}
                                    placeholder="Ej. 2"
                                />
                            </div>

                            <button type="submit" disabled={isSaving} className="w-full bg-violet-600 text-white py-4 rounded-xl font-bold hover:bg-violet-700 transition-all">
                                {isSaving ? 'Guardando...' : 'GUARDAR FACTURACION'}
                            </button>
                        </form>
                    </div>
                </div>
            )}

            {/* MODAL DE CONFIRMACIÓN DE ELIMINACIÓN */}
            {confirmingDelete && (
                <div className="fixed inset-0 z-[2000] bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
                    <div className="bg-white rounded-3xl p-8 max-w-md w-full shadow-2xl border-t-4 border-error">
                        <div className="flex items-center gap-4 mb-4">
                            <div className="w-12 h-12 rounded-full bg-error/10 flex items-center justify-center">
                                <span className="material-symbols-outlined text-error text-2xl">warning</span>
                            </div>
                            <div>
                                <h3 className="text-lg font-black text-on-surface">¿Eliminar colegio?</h3>
                                <p className="text-xs text-slate-400 font-bold">Código: <span className="text-error">{confirmingDelete}</span></p>
                            </div>
                        </div>
                        <p className="text-sm text-slate-600 font-medium mb-8 leading-relaxed">
                            Esta acción eliminará <strong>permanentemente</strong> el registro del colegio, los permisos del administrador y su cuenta de acceso. Esta operación <strong>no se puede deshacer</strong>.
                        </p>
                        <div className="flex gap-4">
                            <button
                                onClick={() => setConfirmingDelete(null)}
                                disabled={isDeleting}
                                className="flex-1 py-3 rounded-xl border-2 border-slate-200 text-slate-600 font-bold text-sm hover:bg-slate-50 transition-colors"
                            >
                                Cancelar
                            </button>
                            <button
                                onClick={handleDelete}
                                disabled={isDeleting}
                                className="flex-1 py-3 rounded-xl bg-error text-white font-bold text-sm hover:bg-error/90 transition-colors flex items-center justify-center gap-2"
                            >
                                {isDeleting ? (
                                    <div className="animate-spin w-5 h-5 border-2 border-white/30 border-t-white rounded-full"></div>
                                ) : (
                                    <>
                                        <span className="material-symbols-outlined text-sm">delete_forever</span>
                                        Confirmar Eliminación
                                    </>
                                )}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </DashboardLayout>
    );
};

export default CompaniesPage;
