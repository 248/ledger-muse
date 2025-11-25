"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

const highlights = [
  {
    title: "家計簿×レシートOCR",
    description: "アップロードから明細化までを分離し、Cloud Run / Pub/Sub で拡張可能に。",
  },
  {
    title: "ナレッジ管理",
    description: "取引メモやタグを一緒に扱い、検索で素早く引き出せる構造を前提に設計。",
  },
  {
    title: "学習から商用へ",
    description: "Firebase App Hosting + GCP マネージドサービスで低コストに開始し、Terraform 管理で移行可能。",
  },
];

type HealthStatus = {
  status: string;
  version?: string;
};

const BACKEND_BASE =
  process.env.NEXT_PUBLIC_BACKEND_API_BASE ?? "http://localhost:8080";

export default function HomePage() {
  const [health, setHealth] = useState<HealthStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchHealth = async () => {
      setLoading(true);
      setError(null);
      try {
        const res = await fetch(`${BACKEND_BASE}/health`);
        if (!res.ok) {
          throw new Error(`status ${res.status}`);
        }
        const data = (await res.json()) as HealthStatus;
        setHealth(data);
      } catch (err) {
        console.error("Health check failed:", err);
        setError("バックエンドへの接続に失敗しました");
      } finally {
        setLoading(false);
      }
    };

    fetchHealth();
  }, []);

  return (
    <main className="min-h-screen bg-gradient-to-b from-slate-50 via-white to-sky-50">
      <section className="mx-auto max-w-5xl px-6 pb-12 pt-16 sm:pt-20">
        <p className="text-sm font-semibold uppercase tracking-wide text-sky-700">
          Hello, Ledger Muse
        </p>
        <h1 className="mt-3 text-4xl font-bold tracking-tight text-slate-900 sm:text-5xl">
          Ledger Muse
        </h1>
        <p className="mt-4 max-w-3xl text-lg leading-relaxed text-slate-700">
          家計簿・レシートOCR・ナレッジを統合する学習用モノレポ。
          Firebase App Hosting と Cloud Run を土台に、将来の商用化まで見据えた構成で進めます。
        </p>
        <div className="mt-6 flex flex-wrap items-center gap-3">
          <Link
            href="/"
            className="inline-flex items-center rounded-full bg-sky-700 px-4 py-2 text-sm font-semibold text-white shadow-md transition hover:bg-sky-800 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-700"
          >
            はじめる
          </Link>
          <Link
            href="#highlights"
            className="text-sm font-semibold text-sky-800 underline-offset-4 transition hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-700"
          >
            概要を見る
          </Link>
        </div>
      </section>

      <section className="mx-auto max-w-5xl px-6 pb-10">
        <div className="rounded-2xl border border-slate-200 bg-white/90 p-5 shadow-sm">
          <h2 className="text-base font-semibold text-slate-900">
            バックエンド接続
          </h2>
          <p className="mt-2 text-sm text-slate-700">
            Cloud Run/Echo のヘルスチェックを叩いて疎通を確認します。
          </p>
          <div className="mt-3 rounded-lg border border-slate-100 bg-slate-50 px-4 py-3 text-sm text-slate-800">
            {loading && <span>バックエンド接続を確認中…</span>}
            {!loading && health && (
              <span>
                バックエンド: {health.status.toUpperCase()}{" "}
                {health.version ? `(${health.version})` : null}
              </span>
            )}
            {!loading && !health && error && (
              <span className="text-rose-600">{error}</span>
            )}
          </div>
        </div>
      </section>

      <section
        id="highlights"
        className="mx-auto max-w-5xl px-6 pb-16 sm:pb-20 lg:pb-24"
      >
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {highlights.map((item) => (
            <article
              key={item.title}
              className="rounded-2xl border border-slate-200 bg-white/80 p-5 shadow-sm backdrop-blur-sm"
            >
              <h2 className="text-lg font-semibold text-slate-900">
                {item.title}
              </h2>
              <p className="mt-2 text-sm leading-relaxed text-slate-700">
                {item.description}
              </p>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
