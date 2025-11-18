import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Ledger Muse",
  description: "Household finance app with receipt OCR and knowledge notes",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja">
      <body className="min-h-screen bg-slate-50 text-slate-900">
        <div className="mx-auto max-w-5xl p-6">{children}</div>
      </body>
    </html>
  );
}
