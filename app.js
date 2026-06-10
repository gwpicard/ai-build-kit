const timeEl = document.querySelector("#time");
const periodEl = document.querySelector("#period");
const dateEl = document.querySelector("#date");
const timezoneEl = document.querySelector("#timezone");
const offsetEl = document.querySelector("#offset");

const locale = navigator.language || "en-US";
const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone || "Local timezone";

const timeFormatter = new Intl.DateTimeFormat(locale, {
  hour: "numeric",
  minute: "2-digit",
  second: "2-digit",
});

const dateFormatter = new Intl.DateTimeFormat(locale, {
  weekday: "long",
  month: "long",
  day: "numeric",
  year: "numeric",
});

function formatOffset(date) {
  const offsetMinutes = -date.getTimezoneOffset();
  const sign = offsetMinutes >= 0 ? "+" : "-";
  const absoluteMinutes = Math.abs(offsetMinutes);
  const hours = String(Math.floor(absoluteMinutes / 60)).padStart(2, "0");
  const minutes = String(absoluteMinutes % 60).padStart(2, "0");

  return `UTC${sign}${hours}:${minutes}`;
}

function updateClock() {
  const now = new Date();
  const parts = timeFormatter.formatToParts(now);
  const dayPeriod = parts.find((part) => part.type === "dayPeriod")?.value;

  timeEl.textContent = timeFormatter.format(now);
  timeEl.dateTime = now.toISOString();
  periodEl.textContent = dayPeriod ? `${dayPeriod} in your browser's location` : "In your browser's location";
  dateEl.textContent = dateFormatter.format(now);
  timezoneEl.textContent = timezone.replaceAll("_", " ");
  offsetEl.textContent = formatOffset(now);
}

updateClock();
setInterval(updateClock, 1000);
