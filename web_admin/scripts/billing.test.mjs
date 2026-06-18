import test from "node:test";
import assert from "node:assert/strict";
import {
  validateBillingPatch,
  normalizeBilling,
  calculateMrr,
  calculateMonthlyCharge,
  usageRatio,
} from "../src/lib/billing.js";

test("validateBillingPatch acepta plan y precio por estudiante", () => {
  const result = validateBillingPatch({ plan: "standard", pricePerStudentUsd: 1.25, status: "active" });
  assert.equal(result.ok, true);
  assert.equal(result.billing.plan, "standard");
  assert.equal(result.billing.pricePerStudentUsd, 1.25);
});

test("validateBillingPatch rechaza plan invalido", () => {
  const result = validateBillingPatch({ plan: "enterprise" });
  assert.equal(result.ok, false);
});

test("normalizeBilling aplica defaults", () => {
  const billing = normalizeBilling({ plan: "premium" });
  assert.equal(billing.plan, "premium");
  assert.equal(billing.pricePerStudentUsd, 0);
  assert.equal(billing.driverLimit, 2);
});

test("calculateMonthlyCharge usa estudiantes activos x precio", () => {
  const total = calculateMonthlyCharge({
    billingStatus: "active",
    studentsActive: 40,
    pricePerStudentUsd: 1.5,
  });
  assert.equal(total, 60);
});

test("calculateMrr solo suma colegios activos o en prueba", () => {
  const mrr = calculateMrr([
    { billingStatus: "active", studentsActive: 10, pricePerStudentUsd: 2 },
    { billingStatus: "suspended", studentsActive: 50, pricePerStudentUsd: 2 },
    { billingStatus: "trial", studentsActive: 5, pricePerStudentUsd: 3 },
  ]);
  assert.equal(mrr, 35);
});

test("usageRatio limita a 100", () => {
  assert.equal(usageRatio(10, 8), 100);
});