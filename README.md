# 🍞 burnt

Cross-platform toasts for React Native, powered by native elements.

- [Install](#installation)
- [Usage](#api)

Now with Android, iOS & Web Support.


## Interactive native dialogs (fork extension)

This fork adds `dialog()`, `confirm()`, `prompt()`, and `dismissAllDialogs()`.
Unlike the original transient Burnt `alert()`, these are interactive dialogs and return user decisions.
Both mobile implementations render **native views outside the React Native component tree**:
iOS uses a scene-bound overlay `UIWindow`; Android uses an Activity-owned `Dialog` window.
No `SYSTEM_ALERT_WINDOW` permission is required.

```tsx
import * as Burnt from "burnt";

const confirmed = await Burnt.confirm({
  title: "Delete comment",
  message: "This operation cannot be undone.",
  confirmText: "Delete",
  cancelText: "Cancel",
  destructive: true,
});

if (confirmed) await deleteComment();

const reason = await Burnt.prompt({
  title: "Rejection reason",
  placeholder: "Describe the reason...",
  multiline: true,
  required: true,
  maxLength: 500,
});
if (reason !== null) await rejectTask(reason);
```

For full control, call `Burnt.dialog(options)` with unique action IDs, optional fields, a
`queuePolicy` of `enqueue` (default), `replace` or `reject`, and
`dismissOnBackdrop`/`dismissOnBack`. The return type is a discriminated union:

```ts
type DialogResult =
  | { status: "action"; actionId: string; values: Record<string, string> }
  | { status: "dismissed"; reason: "backdrop" | "back" | "programmatic" | "lifecycle" };
```

Calling `dismissAllDialogs()` resolves all queued and active dialogs as dismissed.
All fields are required to have unique IDs. `required` fields are validated before any
non-cancel action. `maxLength` is enforced natively. Cancel actions do not validate input.

### Presentation and lifecycle

- iOS: creates a separate `UIWindow` in the active `UIWindowScene` above ordinary
  React Native modals. On dismissal, restores the previous key window when still valid.
- Android: uses an Activity-bound Dialog window (no special system overlay permission);
  its z-order is above existing Activity windows and React Native modal dialogs.
- Dialog requests are serialized. Scene/activity loss dismisses pending requests.
- Existing `toast()`, `alert()` and `dismissAllAlerts()` are unchanged.
- For RN apps without Expo as an application framework, `expo-modules-core` must still be
  installed/configured because Burnt itself is an Expo Modules native module.
- Web support is a minimal browser `confirm`/`prompt` fallback, not a pixel-matched modal.
- Native iOS and Android changes require an application rebuild; JS reload alone is not enough.

### Manual native acceptance suite

In `example/App.tsx`, run both **Confirm Dialog** and **Prompt Dialog** directly on the screen
and inside **Open Modal** (form sheet). Then verify:
1. Dialog stays above the existing RN modal; cancelling leaves modal open.
2. Prompt input appears, keyboard doesn't cover actions, max length and required fields work.
3. Opening two dialogs serializes the results; `replace` and `reject` policies behave correctly.
4. Back/backdrop dismissal, programmatic dismissal and lifecycle interruption settle once.
5. Original Burnt alerts and toasts remain visible on top of modals.

**Important:** The original example uses Expo SDK 47 / RN 0.70. Upgrade its
development environment before treating it as a modern RN compatibility test.
The extension should be built and tested with your application's actual React Native version,
both old and new architecture, on iOS and Android devices.

## Alerts

https://user-images.githubusercontent.com/13172299/202289223-8a333223-3afa-49c4-a001-a70c76150ef0.mp4

## ...and Toasts

https://user-images.githubusercontent.com/13172299/231801324-3f0858a6-bd61-4d74-920f-4e77b80d26c1.mp4

## ...and Web Support

https://user-images.githubusercontent.com/13172299/236826405-b5f423bb-dafd-4013-a941-7accbea43c14.mp4

## Context

See this
[Twitter thread](https://twitter.com/FernandoTheRojo/status/1592923529644625920).

## What

This is a library with a `toast` and `alert` method for showing ephemeral UI.

On iOS, it wraps [`SPIndicator`](https://github.com/ivanvorobei/SPIndicator) and
[`AlertKit`](https://github.com/sparrowcode/AlertKit).

On Android, it wraps `ToastAndroid` from `react-native`. `Burnt.alert()` falls
back to `Burnt.toast()` on Android. This may change in a future version.

On Web, it wraps [`sonner`](https://github.com/emilkowalski/sonner) by Emil
Kowalski.

Burnt works with both the old & new architectures. It's built on top of JSI,
thanks to Expo's new module system.

## Features

- Simple, imperative `toast` that uses **native** components under the hood,
  rather than using React state with JS-based UI.
- Animated icons
- iOS App Store-like `alert` popups
- Overlays on top of native iOS modals
- Loading alerts

## Modals

Displaying toasts on top of modals has always been an issue in React Native.
With Burnt, this works out of the box.

https://user-images.githubusercontent.com/13172299/231801096-2894fbf3-4df7-45d7-9c72-f80d36fd45ef.mp4

## Usage

```tsx
import * as Burnt from "burnt";

Burnt.toast({
  title: "Burnt installed.",
  preset: "done",
  message: "See your downloads.",
});
```

You can also `Burnt.alert()` and `Burnt.dismissAllAlerts()`.

## TODO

- [x] iOS support
- [x] Android support
- [x] Custom iOS icons
- [x] Web support

## Installation

```sh
yarn add burnt
```

### Expo

Burnt likely requires Expo SDK 46+.

```sh
npx expo install burnt
```

Then, you'll need to rebuild your dev client. Burnt will not work in Expo Go.

```sh
npx expo prebuild
npx expo run:ios
```

### Web Support

To enable Web support, you need to add the `<Toaster />` to the root of your
app. If you're using Next.js, add this into your `_app.tsx` component.

```tsx
// _app.tsx
import { Toaster } from "burnt/web";

function MyApp({ Component, pageProps }) {
  return (
    <>
      <Component {...pageProps} />
      <Toaster position='bottom-right' />
    </>
  );
}
```

If you're using Next.js, add `burnt` to your `transpilePackages` in `next.config.js`.

```tsx
/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: [
    // Your other packages here
    "burnt"
  ]
}
```

To configure your `Toaster`, please reference the `sonner`
[docs](https://github.com/emilkowalski/sonner/tree/main#theme).


### Plain React Native

```sh
pod install
```

### Solito

```sh
cd applications/app
expo install burnt expo-build-properties
npx expo prebuild --clean
npx expo run:ios
cd ../..
yarn
```

Be sure to also follow the [expo](#expo) instructions and [web](#web-support)
instructions.

## API

### `toast`

https://user-images.githubusercontent.com/13172299/202275423-300671e5-3918-4d5d-acae-0602160de252.mp4

`toast(options): Promise<void>`

```tsx
Burnt.toast({
  title: "Congrats!", // required

  preset: "done", // or "error", "none", "custom"

  message: "", // optional

  haptic: "none", // or "success", "warning", "error"

  duration: 2, // duration in seconds

  shouldDismissByDrag: true,

  from: "bottom", // "top" or "bottom"

  // optionally customize layout
  layout: {
    iconSize: {
      height: 24,
      width: 24,
    },
  },
  icon: {
    ios: {
      // SF Symbol. For a full list, see https://developer.apple.com/sf-symbols/.
      name: "checkmark.seal",
      color: "#1D9BF0",
    },
    web: <Icon />,
  },
});
```

### `alert`

https://user-images.githubusercontent.com/13172299/202275324-4f6cb5f5-a103-49b5-993f-2030fc836edb.mp4

_The API changed since recording this video. It now uses object syntax._

`alert(options): Promise<void>`

```tsx
import * as Burnt from "burnt";

export const alert = () => {
  Burnt.alert({
    title: "Congrats!", // required

    preset: "done", // or "error", "heart", "custom"

    message: "", // optional

    duration: 2, // duration in seconds

    // optionally customize layout
    layout: {
      iconSize: {
        height: 24,
        width: 24,
      },
    },
    icon: {
      ios: {
        // SF Symbol. For a full list, see https://developer.apple.com/sf-symbols/.
        name: "checkmark.seal",
        color: "#1D9BF0",
      },
      web: <Icon />,
    },
  });
};
```

On Web, this will display a regular toast. This may change in the future.

### `dismissAllAlerts()`

Does what you think it does! In the future, I'll allow async spinners for
promises, and it'll be useful then.

## Contribute

```sh
yarn build
cd example
yarn
npx expo run:ios # do this again whenever you change native code
```

You can edit the iOS files in `ios/`, and then update the JS accordingly in
`src`.

## Thanks

Special thanks to [Tomasz Sapeta](https://twitter.com/tsapeta) for offering help
along the way.

Expo Modules made this so easy to build, and all with Swift – no Objective C.
It's my first time writing Swift, and it was truly a breeze.
