import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Team tool",
  description: "A private tool for your team",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
