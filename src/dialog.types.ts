export type DialogActionStyle = "default" | "cancel" | "destructive";
export type DialogIcon = "none" | "info" | "success" | "warning" | "error";
export type DialogQueuePolicy = "enqueue" | "replace" | "reject";

export type DialogAction = {
  id: string;
  title: string;
  style?: DialogActionStyle;
};

export type DialogField = {
  id: string;
  type: "text" | "textarea";
  placeholder?: string;
  value?: string;
  required?: boolean;
  maxLength?: number;
};

export type DialogOptions = {
  title: string;
  message?: string;
  icon?: DialogIcon;
  fields?: DialogField[];
  actions: DialogAction[];
  dismissOnBackdrop?: boolean;
  dismissOnBack?: boolean;
  queuePolicy?: DialogQueuePolicy;
};

export type DialogResult =
  | { status: "action"; actionId: string; values: Record<string, string> }
  | { status: "dismissed"; reason: "backdrop" | "back" | "programmatic" | "lifecycle" };

export type ConfirmOptions = {
  title: string;
  message?: string;
  icon?: DialogIcon;
  confirmText?: string;
  cancelText?: string;
  destructive?: boolean;
  queuePolicy?: DialogQueuePolicy;
};

export type PromptOptions = ConfirmOptions & {
  placeholder?: string;
  value?: string;
  required?: boolean;
  maxLength?: number;
  multiline?: boolean;
};
