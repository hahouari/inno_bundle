# Inno Setup

![Static Badge](https://img.shields.io/badge/Flutter_Community-Inno_Setup-blue)

A command-line tool which simplifies building a windows installer. Customizable with options to
configure some installer options.

*Note: This package is tested on Inno Setup version 6.2.2.*

## Guide

### 1. Download Inno Setup

Download the Inno Setup [from here](https://jrsoftware.org/isdl.php), then install it.

### 2. Generate App ID

To generate a random one run:

```shell
dart run inno_setup:id
```

If you want your app id based upon a namespace, that is also possible:

```shell
dart run inno_setup:id --ns "www.example.com"
```

The output id is going to be something similar to this:

> f887d5f0-4690-1e07-8efc-d16ea7711bfb

Paste this id into your `pubspec.yaml` file, under `inno_setup.id`.

### 2. Setup the Configuration

Add your configuration to your `pubspec.yaml`. example:

```yaml
dev_dependencies:
  inno_setup: "^0.0.1"

inno_setup:
  id: f887d5f0-4690-1e07-8efc-d16ea7711bfb # <-- put your own generated one
  publisher: Your Name
  installer_icon: assets/images/installer.ico
```

*Note: you have to provide your own installer icon. Only **.ico** images were tested.*

### 3. Build the Installer

After setting up the configuration, all that is left to do is run the package.

```shell
flutter pub get
dart run inno_setup:build --release
```

*Note: `--release` flag is required if you want to build for release mode, see below for other
options.

If you encounter any
issues [please report them here](https://github.com/hahouari/inno_setup/issues).

## Attributes

Shown below is the full list of attributes which you can specify within your configuration.
All configuration attributes should be under `inno_setup`.

- `id`: `Required` A valid GUID that serves as an AppId.
- `name`: App name. Defaults to camel cased `name` from `pubspec.yaml`.
- `description`: Defaults to `description` from `pubspec.yaml`.
- `version`: Defaults to `version` from `pubspec.yaml`.
- `publisher`: Defaults to `maintainer` from `pubspec.yaml`. Otherwise, an empty string.
- `url`: Defaults to `homepage` from `pubspec.yaml`. Otherwise, an empty string.
- `support_url`: Defaults to `url`.
- `updates_url`: Defaults to `url`.
- `installer_icon`: `Required` A valid path relative to the project that points to an ico image.
- `languages`: Defaults to all available language<sup>1</sup>.
- `admin`: (`true` or `false`) Defaults to `true`
    - `true`: Require elevated privileges during installation. App will install globally on the end
      user machine.
    - `false`: Don't require elevated privileges during installation. App will install into
      user-specific folder.

<sup>1</sup> All Supported Languages are: english, armenian, brazilianportuguese, bulgarian, catalan,
corsican, czech, danish, dutch, finnish, french, german, hebrew, hungarian, icelandic, italian,
japanese, norwegian, polish, portuguese, russian, slovak, slovenian, spanish, turkish, ukrainian.

Another example including languages:

```yaml
inno_setup:
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
dart run inno_setup:build --skip-app
```

This build is `release` mode:

```shell
dart run inno_setup:build --release
```

Other mode flags are `--profile`, `--debug` (Default).
