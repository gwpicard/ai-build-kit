import "server-only";
import nodemailer from "nodemailer";
import { secretFile } from "./config";

export async function sendSignInLink(email: string, url: string) {
  const host = process.env.SMTP_HOST;
  const from = process.env.SMTP_FROM;
  if (!host || !from) throw new Error("SMTP_HOST and SMTP_FROM are required for email sign-in");
  const transport = nodemailer.createTransport({
    host, port: Number(process.env.SMTP_PORT ?? 587),
    secure: process.env.SMTP_PORT === "465", requireTLS: true,
    ...(process.env.SMTP_USER ? { auth: { user: process.env.SMTP_USER,
      pass: secretFile("SMTP_PASSWORD_FILE") } } : {}),
    logger: false, debug: false,
  });
  try {
    await transport.sendMail({ from, to: email, subject: "Your sign-in link",
      text: `Use this link to sign in. It expires in ten minutes and works once.\n\n${url}` });
  } catch {
    throw new Error("The sign-in email could not be sent");
  } finally { transport.close(); }
}
