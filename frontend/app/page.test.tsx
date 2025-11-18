import { render, screen } from "@testing-library/react";
import HomePage from "./page";

describe("HomePage", () => {
  it("renders headline text", () => {
    render(<HomePage />);
    expect(screen.getByText("Ledger Muse")).toBeInTheDocument();
  });
});
