"use client";

import Link from "next/link";
import { signIn, useSession } from "next-auth/react";
import { useEffect } from "react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const { status } = useSession();
  const router = useRouter();

  useEffect(() => {
    if (status === "authenticated") {
      router.replace("/dashboard");
    }
  }, [status, router]);

  return (
    <main className="space-y-6 rounded-2xl bg-white/90 p-8 shadow-sm">
      <div className="space-y-2">
        <p className="text-sm font-semibold uppercase tracking-wide text-sky-700">
          Sign in
        </p>
        <h1 className="text-3xl font-bold text-slate-900">ログイン</h1>
        <p className="text-sm text-slate-700">
          Google アカウントでサインインして、ダッシュボードと家計簿機能にアクセスします。
        </p>
      </div>

      <div className="space-y-3">
        <button
          type="button"
          onClick={() => signIn("google", { callbackUrl: "/dashboard" })}
          className="inline-flex w-full items-center justify-center gap-2 rounded-lg bg-sky-700 px-4 py-3 text-sm font-semibold text-white shadow-md transition hover:bg-sky-800 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-700"
        >
          Googleでログイン
        </button>
        <p className="text-xs text-slate-500">
          サインインにより、利用規約とプライバシーポリシーに同意したものとみなされます。
        </p>
      </div>

      <div className="rounded-lg border border-slate-200 bg-slate-50 p-4 text-sm text-slate-700">
        <p className="font-semibold text-slate-900">開発中のためのメモ</p>
        <ul className="mt-2 list-disc space-y-1 pl-5">
          <li>Identity Platform の Google プロバイダが有効になっていることを確認してください。</li>
          <li>
            ローカル環境では `.env.local` に <code>AUTH_GOOGLE_ID</code>,{" "}
            <code>AUTH_GOOGLE_SECRET</code>, <code>AUTH_SECRET</code> を設定してください。
          </li>
        </ul>
      </div>

      <div className="flex items-center justify-between text-sm text-slate-600">
        <span>まだアカウントをお持ちでない場合は Google で作成できます。</span>
        <Link
          href="/"
          className="font-semibold text-sky-700 underline-offset-4 hover:underline"
        >
          トップへ戻る
        </Link>
      </div>
    </main>
  );
}
