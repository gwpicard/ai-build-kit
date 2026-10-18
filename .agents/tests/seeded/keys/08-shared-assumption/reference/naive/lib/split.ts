// The builder's likely first answer, for the rehearsal only. SEEDED-KEY-08-c41a96e2
export function splitBill(totalPence: number, people: number): number[] {
  return Array.from({ length: people }, () => Math.round(totalPence / people));
}
