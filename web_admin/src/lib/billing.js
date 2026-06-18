export const BILLING_PLANS = ["basic", "standard", "premium"];
export const BILLING_STATUSES = ["active", "trial", "suspended", "cancelled"];

export const DEFAULT_BILLING = {
  plan: "basic",
  pricePerStudentUsd: 0,
  status: "active",
  studentLimit: 80,
  driverLimit: 2,
};

/** Precio sugerido USD por estudiante activo / mes */
export const PLAN_PRESETS = {
  basic: { pricePerStudentUsd: 1, studentLimit: 80, driverLimit: 2 },
  standard: { pricePerStudentUsd: 0.85, studentLimit: 200, driverLimit: 5 },
  premium: { pricePerStudentUsd: 0.7, studentLimit: 500, driverLimit: 15 },
};

export function roundUsd(amount) {
  return Math.round((Number(amount) || 0) * 100) / 100;
}

export function resolvePricePerStudentUsd(billing = {}) {
  if (billing.pricePerStudentUsd != null && billing.pricePerStudentUsd !== "") {
    return Math.max(0, Number(billing.pricePerStudentUsd) || 0);
  }
  return 0;
}

export function normalizeBilling(input = {}) {
  return {
    plan: BILLING_PLANS.includes(input.plan) ? input.plan : DEFAULT_BILLING.plan,
    pricePerStudentUsd: Math.max(0, Number(input.pricePerStudentUsd) || 0),
    status: BILLING_STATUSES.includes(input.status) ? input.status : DEFAULT_BILLING.status,
    studentLimit: Math.max(1, Math.floor(Number(input.studentLimit) || DEFAULT_BILLING.studentLimit)),
    driverLimit: Math.max(1, Math.floor(Number(input.driverLimit) || DEFAULT_BILLING.driverLimit)),
  };
}

export function validateBillingPatch(patch) {
  if (!patch || typeof patch !== "object") {
    return { ok: false, error: "Datos de facturacion invalidos" };
  }

  const billing = {};
  if (patch.plan !== undefined) {
    if (!BILLING_PLANS.includes(patch.plan)) {
      return { ok: false, error: `Plan invalido. Usa: ${BILLING_PLANS.join(", ")}` };
    }
    billing.plan = patch.plan;
  }
  if (patch.status !== undefined) {
    if (!BILLING_STATUSES.includes(patch.status)) {
      return { ok: false, error: `Estado invalido. Usa: ${BILLING_STATUSES.join(", ")}` };
    }
    billing.status = patch.status;
  }
  if (patch.pricePerStudentUsd !== undefined) {
    const pricePerStudentUsd = Number(patch.pricePerStudentUsd);
    if (Number.isNaN(pricePerStudentUsd) || pricePerStudentUsd < 0) {
      return { ok: false, error: "Precio por estudiante debe ser un numero >= 0" };
    }
    billing.pricePerStudentUsd = pricePerStudentUsd;
  }
  if (patch.studentLimit !== undefined) {
    const studentLimit = Math.floor(Number(patch.studentLimit));
    if (Number.isNaN(studentLimit) || studentLimit < 1) {
      return { ok: false, error: "Limite de estudiantes debe ser >= 1" };
    }
    billing.studentLimit = studentLimit;
  }
  if (patch.driverLimit !== undefined) {
    const driverLimit = Math.floor(Number(patch.driverLimit));
    if (Number.isNaN(driverLimit) || driverLimit < 1) {
      return { ok: false, error: "Limite de conductores debe ser >= 1" };
    }
    billing.driverLimit = driverLimit;
  }

  return { ok: true, billing };
}

/** Cobro mensual = estudiantes activos × precio por estudiante */
export function calculateMonthlyCharge(company = {}) {
  const status = company.billingStatus || company.billing?.status || "active";
  if (status !== "active" && status !== "trial") return 0;

  const studentsActive = Math.max(0, Number(company.studentsActive) || 0);
  const price = resolvePricePerStudentUsd({
    ...(company.billing || {}),
    pricePerStudentUsd: company.pricePerStudentUsd ?? company.billing?.pricePerStudentUsd,
  });

  return roundUsd(studentsActive * price);
}

export function calculateMrr(companies = []) {
  return roundUsd(companies.reduce((sum, company) => sum + calculateMonthlyCharge(company), 0));
}

export function usageRatio(used, limit) {
  const safeLimit = Math.max(1, Number(limit) || 1);
  const safeUsed = Math.max(0, Number(used) || 0);
  return Math.min(100, Math.round((safeUsed / safeLimit) * 100));
}

export function usageTone(used, limit) {
  const ratio = usageRatio(used, limit);
  if (ratio >= 100) return "danger";
  if (ratio >= 80) return "warning";
  return "ok";
}

export function enrichCompanyBilling(row) {
  const billing = row.billing || DEFAULT_BILLING;
  const pricePerStudentUsd = resolvePricePerStudentUsd(billing);
  const monthlyChargeUsd = calculateMonthlyCharge({
    ...row,
    billing,
    pricePerStudentUsd,
  });

  return {
    ...row,
    billing,
    billingPlan: billing.plan || "basic",
    billingStatus: billing.status || "active",
    pricePerStudentUsd,
    monthlyChargeUsd,
    studentLimit: billing.studentLimit ?? DEFAULT_BILLING.studentLimit,
    driverLimit: billing.driverLimit ?? DEFAULT_BILLING.driverLimit,
  };
}
