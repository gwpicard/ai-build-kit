import { formatTime } from "./time.js";

const app = document.querySelector("#app");

if (app) {
  const setupNote = document.createElement("p");
  setupNote.textContent = `Test clock value: ${formatTime({ hour: 3, minute: 5 })}`;
  app.append(setupNote);
}
