import { expect, test } from "@playwright/test";

test("トップページが表示され、バックエンド疎通状態を示す", async ({ page }) => {
  await page.goto("/");

  await expect(page.getByRole("heading", { name: "Ledger Muse" })).toBeVisible();

  // バックエンドが起動していない場合はエラー表示、起動している場合は OK 表示を許容
  await expect(
    page.getByRole("heading", { name: "バックエンド接続" }),
  ).toBeVisible();

  const errorText = page.getByText(/バックエンドへの接続に失敗しました/);
  const okText = page.getByText(/バックエンド: OK/);

  const result = await Promise.race([
    errorText.waitFor({ timeout: 5000 }).then(() => "error"),
    okText.waitFor({ timeout: 5000 }).then(() => "ok"),
  ]);

  expect(result === "error" || result === "ok").toBeTruthy();
});
