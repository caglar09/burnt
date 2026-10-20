import { AlertOptions, ToastOptions } from "./types";
import { ToastAndroid } from "react-native";
import { requireNativeModule } from "expo-modules-core";
import type { DialogOptions, DialogResult } from "./dialog.types";

const NativeDialogs = requireNativeModule("Burnt");

export default {
  alertAsync({ message, title, preset, duration }: AlertOptions) {
    this.toastAsync({
      message,
      title,
      preset: preset == "done" ? "done" : preset == "error" ? "error" : "done",
      duration,
    });
  },
  toastAsync({ title, duration = 5, from = 'bottom' }: Pick<ToastOptions, "title" | "duration" | "from">) {
    ToastAndroid.showWithGravityAndOffset(
      title,
      duration * 1000,
      from === 'bottom' ? ToastAndroid.BOTTOM : ToastAndroid.TOP,
      25,
      50
    );
  },
  dialogAsync(options: DialogOptions): Promise<DialogResult> {
    return NativeDialogs.dialogAsync(options);
  },
  dismissAllDialogsAsync(): Promise<void> {
    return NativeDialogs.dismissAllDialogsAsync();
  },
  dismissAllAlertsAsync() {},
};
