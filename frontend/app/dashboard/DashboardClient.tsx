"use client";

import type { Session } from "next-auth";
import { signOut } from "next-auth/react";

type Props = {
  session: Session;
};

export default function DashboardClient({ session }: Props) {
  const user = session.user;

  return (
    <div className="space-y-3 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-semibold text-slate-700">ようこそ</p>
          <p className="text-xl font-bold text-slate-900">
            {user?.name ?? "ユーザー"}
          </p>
          {user?.email ? (
            <p className="text-sm text-slate-600">{user.email}</p>
          ) : null}
        </div>
        <button
          type="button"
          onClick={() => signOut({ callbackUrl: "/login" })}
          className="inline-flex items-center rounded-md border border-slate-300 px-3 py-2 text-sm font-semibold text-slate-800 transition hover:bg-slate-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-500"
        >
          ログアウト
        </button>
      </div>
      <div className="rounded-lg border border-slate-100 bg-slate-50 p-4 text-sm text-slate-700">
        <p className="font-semibold text-slate-900">セッション情報</p>
        <ul className="mt-2 space-y-1">
          <li>
            <span className="text-slate-500">ユーザーID:</span>{" "}
            {user?.id ?? "未取得"}
          </li>
          <li>
            <span className="text-slate-500">有効期限:</span>{" "}
            {new Date(session.expires).toLocaleString("ja-JP")}
          </li>
        </ul>
      </div>
    </div>
  );
}
