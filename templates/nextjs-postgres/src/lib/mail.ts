import "server-only";
import nodemailer from "nodemailer";
import { mailConfig } from "./config";

export async function sendMail(message: { to: string; subject: string; text: string }, settings: ReturnType<typeof mailConfig> | ReturnType<typeof import("./config").signInMailConfig> = mailConfig()) {
  const { from, ...config } = settings;
  const transport = nodemailer.createTransport({ ...config, connectionTimeout: 10000,
    greetingTimeout: 10000, socketTimeout: 15000, disableFileAccess: true, disableUrlAccess: true });
  try {
    const result = await transport.sendMail({ from, to: message.to, subject: message.subject, text: message.text });
    if (result.rejected.length) throw new Error("SMTP refused a recipient");
    console.log(JSON.stringify({ event: "mail.sent" }));
  } catch {
    console.log(JSON.stringify({ event: "mail.failed" }));
    throw new Error("Mail could not be sent");
  } finally { transport.close(); }
}
