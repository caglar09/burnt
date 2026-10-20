const isDev =
  typeof __DEV__ !== "undefined"
    ? __DEV__
    : // @ts-expect-error
      typeof process !== "undefined" && process.env.NODE_ENV !== "production";

export default {
  toast() {
    if (isDev) {
      console.log(
        "[burnt] Burnt.alert() is not implemented on this platform. Just making sure you know."
      );
    }
  },
  alert() {
    if (isDev) {
      console.log(
        "[burnt] Burnt.alert() is not implemented on this platform. Just making sure you know."
      );
    }
  },
  dialogAsync(): Promise<import("./dialog.types").DialogResult> {
    return Promise.resolve({ status: "dismissed", reason: "lifecycle" });
  },
  dismissAllDialogsAsync(): Promise<void> { return Promise.resolve(); },
  dismissAllAlerts() {
    if (isDev) {
      console.log(
        "[burnt] Burnt.dismissAllAlerts() is not implemented on this platform. Just making sure you know."
      );
    }
  },
} as any;
