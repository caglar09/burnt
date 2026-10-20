import * as Burnt from "../dialog";
import BurntModule from "../BurntModule";

jest.mock("../BurntModule", () => ({
  __esModule: true,
  default: {
    dialogAsync: jest.fn(),
    dismissAllDialogsAsync: jest.fn(() => Promise.resolve()),
  },
}));

const native = BurntModule as jest.Mocked<typeof BurntModule>;

describe("Burnt native dialogs", () => {
  beforeEach(() => jest.clearAllMocks());

  it("rejects duplicate action identifiers", () => {
    expect(() => Burnt.dialog({
      title: "Delete", actions: [
        { id: "confirm", title: "Yes" },
        { id: "confirm", title: "Yes again" },
      ],
    })).toThrow("unique");
  });

  it("rejects duplicate input identifiers and invalid limits", () => {
    expect(() => Burnt.dialog({
      title: "Prompt", actions: [{ id: "ok", title: "OK" }],
      fields: [{ id: "input", type: "text", maxLength: 0 }],
    })).toThrow("positive");
  });

  it("normalizes defaults and forwards to native", async () => {
    native.dialogAsync.mockResolvedValue({ status: "dismissed", reason: "back" });
    await Burnt.dialog({ title: "Title", actions: [{ id: "ok", title: "OK" }] });
    expect(native.dialogAsync).toHaveBeenCalledWith(expect.objectContaining({
      dismissOnBackdrop: false,
      dismissOnBack: true,
      queuePolicy: "enqueue",
      actions: [{ id: "ok", title: "OK", style: "default" }],
    }));
  });

  it("confirm only resolves true for the confirm action", async () => {
    native.dialogAsync.mockResolvedValueOnce({
      status: "action", actionId: "confirm", values: {},
    }).mockResolvedValueOnce({ status: "dismissed", reason: "back" });
    expect(await Burnt.confirm({ title: "Delete?" })).toBe(true);
    expect(await Burnt.confirm({ title: "Delete?" })).toBe(false);
  });

  it("prompt returns typed text or null after cancellation", async () => {
    native.dialogAsync.mockResolvedValueOnce({
      status: "action", actionId: "confirm", values: { value: "A note" },
    }).mockResolvedValueOnce({ status: "dismissed", reason: "programmatic" });
    expect(await Burnt.prompt({ title: "Reason", multiline: true })).toBe("A note");
    expect(await Burnt.prompt({ title: "Reason" })).toBeNull();
  });

  it("passes dismissal through to the native module", async () => {
    await Burnt.dismissAllDialogs();
    expect(native.dismissAllDialogsAsync).toHaveBeenCalledTimes(1);
  });
});
