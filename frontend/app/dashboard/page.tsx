import { redirect } from "next/navigation";
import { auth } from "@/lib/auth";
import DashboardClient from "./DashboardClient";

export default async function DashboardPage() {
  const session = await auth();

  if (!session) {
    redirect("/login");
  }

  return (
    <main className="space-y-6">
      <div className="space-y-2">
        <p className="text-sm font-semibold uppercase tracking-wide text-sky-700">
          Overview
        </p>
        <h1 className="text-3xl font-bold text-slate-900">ダッシュボード</h1>
        <p className="text-sm text-slate-700">
          認証済みユーザーだけがアクセスできる領域です。レシートOCRや取引管理のエントリポイントになります。
        </p>
      </div>

      <DashboardClient session={session} />
    </main>
  );
}
