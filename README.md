# Inno Bundle

[![pub package](https://img.shields.io/pub/v/inno_bundle.svg)](https://pub.dev/packages/inno_bundle)
[![inno setup](https://img.shields.io/badge/Inno_Setup-v6.2.2-blue)](https://jrsoftware.org/isinfo.php)
![dz flutter community](https://img.shields.io/badge/DZ_Flutter_Community-Inno_Setup-blue)

A command-line tool which simplifies bundling your app into a windows installer. Customizable with
options to
configure some installer options.

## Guide

### 1. Download Inno Setup

Download the Inno Setup <a href="https://jrsoftware.org/isdl.php" target="_blank">from here</a>,
then install it.

*Note: This package is tested on Inno Setup version `6.2.2`.*

### 2. Generate App ID

To generate a random one run:

```shell
dart run inno_bundle:id
```

If you want your app id based upon a namespace, that is also possible:

```shell
dart run inno_bundle:id --ns "www.example.com"
```

The output id is going to be something similar to this:

> f887d5f0-4690-1e07-8efc-d16ea7711bfb

Paste this id into your `pubspec.yaml` file, under `inno_bundle.id`.

### 2. Setup the Configuration

Add your configuration to your `pubspec.yaml`. example:

```yaml
dev_dependencies:
  inno_bundle: "^0.0.1"

inno_bundle:
  id: f887d5f0-4690-1e07-8efc-d16ea7711bfb # <-- put your own generated one
  publisher: Your Name
  installer_icon: assets/images/installer.ico
```

### 3. Build the Installer

After setting up the configuration, all that is left to do is run the package.

```shell
flutter pub get
dart run inno_bundle:build --release
```

*Note: `--release` flag is required if you want to build for `release` mode, see below for other
options.*

## Attributes

Shown below is the full list of attributes which you can specify within your configuration.
All configuration attributes should be under `inno_bundle`.

- `id`: `Required` A valid GUID that serves as an AppId.
- `name`: App name. Defaults to camel cased `name` from `pubspec.yaml`.
- `description`: Defaults to `description` from `pubspec.yaml`.
- `version`: Defaults to `version` from `pubspec.yaml`.
- `publisher`: Defaults to `maintainer` from `pubspec.yaml`. Otherwise, an empty string.
- `url`: Defaults to `homepage` from `pubspec.yaml`. Otherwise, an empty string.
- `support_url`: Defaults to `url`.
- `updates_url`: Defaults to `url`.
- `installer_icon`: `Required` A valid path relative to the project that points to an ico image. If
  you don't have one, download the
  <a href="https://github.com/hahouari/inno_bundle/blob/dev/example/demo_app/assets/images/installer.ico" target="_blank">
  template icon</a> provided with the demo. Only **.ico** images were tested.
- `languages`: Installer's display languages. Defaults to all available language<sup>1</sup>.
- `admin`: (`true` or `false`) Defaults to `true`
    - `true`: Require elevated privileges during installation. App will install globally on the end
      user machine.
    - `false`: Don't require elevated privileges during installation. App will install into
      user-specific folder.

<sup>1</sup> All supported languages are: english, armenian, brazilianportuguese, bulgarian,
catalan,
corsican, czech, danish, dutch, finnish, french, german, hebrew, hungarian, icelandic, italian,
japanese, norwegian, polish, portuguese, russian, slovak, slovenian, spanish, turkish, ukrainian.

Another example including languages:

```yaml
inno_bundle:
  id: f887d5f0-4690-1e07-8efc-d16ea7711bfb
  publisher: Your Name
  installer_icon: assets/images/installer.ico
  language:
    - english
    - french
    - german
  admin: false
```

## Other CLI options

This will skip the app building if it exists, and will straight-forward to create the installer:

```shell
dart run inno_bundle:build --skip-app
```

This build is `release` mode:

```shell
dart run inno_bundle:build --release
```

Other mode flags are `--profile`, `--debug` (Default).

## Additional Feature

DLL files `msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll` are also bundled (if detected in
your machine) with the app when creating the installer. This helps some end-users avoid issues of
missing DLL files when running app after install. To learn more about it, visit
this <a href="https://stackoverflow.com/questions/74329543/how-to-find-the-vcruntime140-dll-in-flutter-build-windows" target="_blank">
Stack Overflow issue</a>.

## Reporting Issues

If you encounter any
issues <a href="https://github.com/hahouari/inno_bundle/issues" target="_blank">please report them
here</a>.
