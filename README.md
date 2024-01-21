# Inno Bundle

[![pub package](https://img.shields.io/pub/v/inno_bundle.svg)](https://pub.dev/packages/inno_bundle)
[![inno setup](https://img.shields.io/badge/Inno_Setup-v6.2.2-blue)](https://jrsoftware.org/isinfo.php)
![dz flutter community](https://img.shields.io/badge/hahouari-Inno_Setup-blue)

A command-line tool that simplifies bundling your app into an EXE installer for
Microsoft Windows. Customizable with options to configure the installer
capabilities.

## Guide

### 1. Download Inno Setup

- **Option 1: Using winget**

```ps
winget install -e --id JRSoftware.InnoSetup
```

- **Option 2: From the website**

  Download Inno Setup from <a href="https://jrsoftware.org/isdl.php" target="_blank">official
  website</a>. Then install it in your machine.

  _Note: This package is tested on Inno Setup version `6.2.2`._

### 2. Install `inno_bundle` package into your project

```ps
dart pub add dev:inno_bundle
```

### 3. Generate App ID

To generate a random id run:

```ps
dart run inno_bundle:id
```

Or, if you want your app id based upon a namespace, that is also possible:

```ps
dart run inno_bundle:id --ns "www.example.com"
```

The output id is going to be something similar to this:

> f887d5f0-4690-1e07-8efc-d16ea7711bfb

Copy & Paste the output to your `pubspec.yaml` as shown in the next step.

### 4. Set up the Configuration

Add your configuration to your `pubspec.yaml`. example:

```yaml
inno_bundle:
  id: f887d5f0-4690-1e07-8efc-d16ea7711bfb # <-- Put your own generated id here
  publisher: Your Name # Optional, but recommended.
```

### 5. Build the Installer

After setting up the configuration, all that is left to do is run the package.

```ps
flutter pub get
dart run inno_bundle:build --release
```

_Note: `--release` flag is required if you want to build for `release` mode, see
below for other options._

## Attributes

Full list of attributes which you can use into your configuration.
All attributes should be under `inno_bundle` in `pubspec.yaml`.

- `id`: `Required` A valid GUID that serves as an AppId.
- `name`: App name. Defaults to camel cased `name` from `pubspec.yaml`.
- `description`: Defaults to `description` from `pubspec.yaml`.
- `version`: Defaults to `version` from `pubspec.yaml`.
- `publisher`: Defaults to `maintainer` from `pubspec.yaml`. Otherwise, an empty
  string.
- `url`: Defaults to `homepage` from `pubspec.yaml`. Otherwise, an empty string.
- `support_url`: Defaults to `url`.
- `updates_url`: Defaults to `url`.
- `installer_icon`: A path relative to the project that points to an ico image.
  Defaults
  to <a href="https://github.com/hahouari/inno_bundle/blob/dev/example/demo_app/assets/images/installer.ico" target="_blank">
  installer icon</a> provided with the demo.<sup><a href="#attributes-more-1">
  &nbsp;1&nbsp;</a></sup>
- `languages`: List of installer's display languages. Defaults to all available
  languages.<sup><a href="#attributes-more-2">&nbsp;2&nbsp;</a></sup>
- `admin`: (`true` or `false`) Defaults to `true`.
  - `true`: Require elevated privileges during installation. App will install
    globally on the end user machine.
  - `false`: Don't require elevated privileges during installation. App will
    install into user-specific folder.

<span id="attributes-more-1"><sup>1</sup></span> Only **.ico** images were
tested.

<span id="attributes-more-2"><sup>2</sup></span> All supported languages are:
english, armenian,
brazilianportuguese, bulgarian, catalan, corsican, czech, danish, dutch,
finnish, french, german,
hebrew, hungarian, icelandic, italian, japanese, norwegian, polish, portuguese,
russian, slovak,
slovenian, spanish, turkish, ukrainian.

## Examples to CLI options

This will skip building the app if it exists:

```ps
dart run inno_bundle:build --no-app
```

This will skip building the installer, useful if you want to generate
`.iss script` only:

```ps
dart run inno_bundle:build --no-installer
```

This build is `release` mode:

```ps
dart run inno_bundle:build --release
```

Other mode flags are `--profile`, `--debug` (Default).

## Other configuration examples

```yaml
inno_bundle:
  id: f887d5f0-4690-1e07-8efc-d16ea7711bfb
  publisher: Jane Doe
  installer_icon: assets/images/installer.ico
  languages:
    - english
    - french
    - german
  admin: false
```

```yaml
inno_bundle:
  id: f887d5f0-4690-1e07-8efc-d16ea7711bfb
  name: google_flutter_framework
  description: Flutter makes it easy and fast to build beautiful apps for mobile and beyond.
  publisher: Google LLC
  url: https://github.com/flutter/flutter
  support_url: https://github.com/flutter/flutter/wiki
  updates_url: https://github.com/flutter/flutter/releases
```

## Additional Feature

DLL files `msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll` are also
bundled (if detected in your machine) with the app when creating the installer.
This helps some end-users avoid issues of missing DLL files when running app
after install. To learn more about it, visit
this <a href="https://stackoverflow.com/questions/74329543/how-to-find-the-vcruntime140-dll-in-flutter-build-windows" target="_blank">
Stack Overflow issue</a>.

## Reporting Issues

If you encounter any
issues <a href="https://github.com/hahouari/inno_bundle/issues" target="_blank">
please report them here</a>.
