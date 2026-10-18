// Reference solution for the rehearsal only. SEEDED-KEY-08-c41a96e2
export function splitBill(totalPence: number, people: number): number[] {
  const base = Math.floor(totalPence / people);
  const extra = totalPence - base * people;
  return Array.from({ length: people }, (_, index) => base + (index < extra ? 1 : 0));
}
