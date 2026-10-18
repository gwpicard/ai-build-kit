export function formatPence(pence: number): string {
  return `£${(pence / 100).toFixed(2)}`;
}
