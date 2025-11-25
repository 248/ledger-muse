import { render, screen } from "@testing-library/react";
import HomePage from "./page";

describe("HomePage", () => {
  it("renders headline text", () => {
    render(<HomePage />);
    expect(screen.getByText("Ledger Muse")).toBeInTheDocument();
  });

  it("describes the integrated experience", () => {
    render(<HomePage />);
    expect(
      screen.getByText(/家計簿.*レシートOCR.*ナレッジ/i),
    ).toBeInTheDocument();
  });

  it("shows a primary call to action", () => {
    render(<HomePage />);
    const cta = screen.getByRole("link", { name: "はじめる" });
    expect(cta).toHaveAttribute("href", "/");
  });

  it("shows loading then backend health result", async () => {
    vi.spyOn(global, "fetch").mockResolvedValueOnce({
      ok: true,
      json: async () => ({ status: "ok", version: "v0.1.0" }),
    } as Response);

    render(<HomePage />);

    expect(screen.getByText("バックエンド接続を確認中…")).toBeInTheDocument();
    expect(await screen.findByText("バックエンド: OK (v0.1.0)")).toBeInTheDocument();
  });

  it("shows error when backend health fails", async () => {
    vi.spyOn(global, "fetch").mockRejectedValueOnce(new Error("network error"));

    render(<HomePage />);

    expect(await screen.findByText(/接続に失敗/i)).toBeInTheDocument();
  });
});
