export function formatTime({ hour, minute }) {
  const normalizedHour = ((hour - 1) % 12) + 1;
  return `${normalizedHour}:${String(minute).padStart(2, "0")}`;
}
