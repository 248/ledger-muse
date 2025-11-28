import { expect, test } from "@playwright/test";

test("未認証ユーザーはダッシュボードへアクセスするとログインへリダイレクトされる", async ({
  page,
}) => {
  await page.goto("/dashboard");

  await expect(page).toHaveURL(/\/login/);
  await expect(page.getByRole("heading", { name: "ログイン" })).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Googleでログイン" }),
  ).toBeVisible();
});
