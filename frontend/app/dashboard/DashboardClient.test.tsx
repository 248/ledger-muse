import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { SessionProvider } from "next-auth/react";
import type { Session } from "next-auth";
import DashboardClient from "./DashboardClient";

const signOutMock = vi.fn();

vi.mock("next-auth/react", async (original) => {
  const mod = await original<{}>();
  return {
    ...mod,
    signOut: (...args: unknown[]) => signOutMock(...args),
  };
});

describe("DashboardClient", () => {
  const session: Session = {
    user: { name: "Alice Example", email: "alice@example.com" },
    expires: new Date(Date.now() + 3600 * 1000).toISOString(),
  };

  beforeEach(() => {
    signOutMock.mockClear();
  });

  it("shows user profile info", () => {
    render(
      <SessionProvider session={session}>
        <DashboardClient session={session} />
      </SessionProvider>,
    );

    expect(screen.getByText("Alice Example")).toBeInTheDocument();
    expect(screen.getByText("alice@example.com")).toBeInTheDocument();
  });

  it("signs out on button click", async () => {
    const user = userEvent.setup();

    render(
      <SessionProvider session={session}>
        <DashboardClient session={session} />
      </SessionProvider>,
    );

    await user.click(screen.getByRole("button", { name: "ログアウト" }));

    expect(signOutMock).toHaveBeenCalledWith({ callbackUrl: "/login" });
  });
});
