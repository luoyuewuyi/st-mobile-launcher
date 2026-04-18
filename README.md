# ST Mobile Launcher

An Android one-tap launcher for running the official [SillyTavern](https://github.com/SillyTavern/SillyTavern) locally through Termux.

This project does not reimplement SillyTavern. It keeps the official SillyTavern app running in Termux and uses a very small Android app to:

1. Trigger the Termux startup script
2. Wait for the local server to become available
3. Open `http://127.0.0.1:8000` in a WebView

That approach is the closest to "same features as normal SillyTavern" while still keeping mobile usage simple.

## What is included

- `termux/install-st.sh`
  - First-time installer
  - Installs `git` and `nodejs-lts`
  - Clones official SillyTavern
  - Runs `npm install`
  - Generates start/stop/update scripts
- `termux/bootstrap.sh`
  - One-command bootstrap entry
- `android/`
  - Minimal Android launcher app
  - Calls `Termux RUN_COMMAND`
  - Opens local SillyTavern in a WebView

## User flow

The intended user experience is:

1. Install Termux once
2. Run one install command in Termux once
3. After that, mostly just tap the launcher app

It is not zero-setup, but after the first setup it is close to one-tap use.

## Quick start

### 1. Install Termux

Use the GitHub or F-Droid build of Termux.

### 2. Run the installer in Termux

```bash
curl -fsSL https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/main/termux/bootstrap.sh | bash
```

If you prefer, you can also run the installer script manually:

```bash
bash install-st.sh
```

### 3. Install the Android launcher APK

Build the APK from [`android`](E:\自己瞎搞\st-mobile-launcher\android) and install it on the phone.

### 4. Grant the first permission

On first app launch, allow the launcher to run commands in the Termux environment.

## Termux commands

```bash
bash ~/sillytavern-mobile/start-st.sh
bash ~/sillytavern-mobile/stop-st.sh
bash ~/sillytavern-mobile/update-st.sh
```

## Current limitations

1. The first setup still requires Termux installation and one manual permission grant.
2. Some Android ROMs are aggressive about background process killing.
3. Initial `npm install` can take time and network bandwidth.
4. The Android launcher is intentionally minimal and does not replace full desktop management tools.

## Android build notes

- The project builds successfully as a debug APK.
- On Windows, the project path contains non-ASCII characters, so `android.overridePathCheck=true` is enabled in `android/gradle.properties`.

Current built APK path:

[`app-debug.apk`](E:\自己瞎搞\st-mobile-launcher\android\app\build\outputs\apk\debug\app-debug.apk)

## Why this design

Trying to fully repackage SillyTavern as a native Android app would create much higher maintenance cost and likely break feature parity. Running the official upstream project in Termux keeps compatibility much higher.
