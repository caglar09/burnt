import BurntModule from "./BurntModule";
import type {
  ConfirmOptions,
  DialogOptions,
  DialogResult,
  PromptOptions,
} from "./dialog.types";

function validate(options: DialogOptions): void {
  if (!options.title?.trim()) throw new Error("[burnt] Dialog title cannot be empty.");
  if (!options.actions?.length) throw new Error("[burnt] Dialog requires at least one action.");
  const actionIds = options.actions.map((action) => action.id);
  if (options.actions.some((action) => !action.id?.trim() || !action.title?.trim()) ||
    new Set(actionIds).size !== actionIds.length) {
    throw new Error("[burnt] Dialog actions require unique non-empty ids and titles.");
  }
  const fields = options.fields ?? [];
  const ids = fields.map((field) => field.id);
  if (fields.some((field) => !field.id?.trim() ||
    (field.maxLength !== undefined && (!Number.isInteger(field.maxLength) || field.maxLength < 1))) ||
    new Set(ids).size !== ids.length) {
    throw new Error("[burnt] Dialog fields require unique ids and a positive integer maxLength.");
  }
}

export function dialog(options: DialogOptions): Promise<DialogResult> {
  validate(options);
  return BurntModule.dialogAsync({
    icon: "none",
    dismissOnBackdrop: false,
    dismissOnBack: true,
    queuePolicy: "enqueue",
    ...options,
    actions: options.actions.map((action) => ({ style: "default", ...action })),
    fields: (options.fields ?? []).map((field) => ({
      value: "",
      required: false,
      ...field,
    })),
  });
}

export function dismissAllDialogs(): Promise<void> {
  return BurntModule.dismissAllDialogsAsync();
}

export async function confirm(options: ConfirmOptions): Promise<boolean> {
  const result = await dialog({
    title: options.title,
    message: options.message,
    icon: options.icon ?? (options.destructive ? "warning" : "info"),
    queuePolicy: options.queuePolicy,
    actions: [
      { id: "cancel", title: options.cancelText ?? "Cancel", style: "cancel" },
      {
        id: "confirm",
        title: options.confirmText ?? "OK",
        style: options.destructive ? "destructive" : "default",
      },
    ],
  });
  return result.status === "action" && result.actionId === "confirm";
}

export async function prompt(options: PromptOptions): Promise<string | null> {
  const result = await dialog({
    title: options.title,
    message: options.message,
    icon: options.icon ?? "none",
    queuePolicy: options.queuePolicy,
    fields: [{
      id: "value",
      type: options.multiline ? "textarea" : "text",
      placeholder: options.placeholder,
      value: options.value ?? "",
      required: options.required,
      maxLength: options.maxLength,
    }],
    actions: [
      { id: "cancel", title: options.cancelText ?? "Cancel", style: "cancel" },
      { id: "confirm", title: options.confirmText ?? "OK",
        style: options.destructive ? "destructive" : "default" },
    ],
  });
  return result.status === "action" && result.actionId === "confirm"
    ? result.values.value ?? ""
    : null;
}
