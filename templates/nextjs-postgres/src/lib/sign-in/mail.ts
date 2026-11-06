import "server-only";
import { sendMail } from "../mail";
import { signInMailConfig } from "../config";

export async function sendSignInLink(email: string, url: string) {
  try {
    await sendMail({ to: email, subject: "Your sign-in link",
      text: `Use this link to sign in. It expires in ten minutes and works once.\n\n${url}` }, signInMailConfig());
  } catch {
    throw new Error("The sign-in email could not be sent");
  }
}
