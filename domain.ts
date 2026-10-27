/** Domain rules to be shared by server actions and validated database procedures. */
export type OilOwnerType = "customer" | "mill";
export type PaymentMethod = "cash" | "bank_transfer" | "check" | "other";
export type PaymentStatus = "unpaid" | "partial" | "paid" | "advance";

export function calculateMillingFee(weightKg: number, ratePerKg: number): number {
  if (!Number.isFinite(weightKg) || weightKg < 0) throw new Error("وزن غير صالح");
  if (!Number.isFinite(ratePerKg) || ratePerKg < 0) throw new Error("تعريفة غير صالحة");
  return Math.round(weightKg * ratePerKg * 100) / 100;
}
