# Inno Bundle

[![pub package](https://img.shields.io/pub/v/inno_bundle.svg)](https://pub.dev/packages/inno_bundle)
[![inno setup](https://img.shields.io/badge/Inno_Setup-v6.4.1-blue)](https://jrsoftware.org/isinfo.php)
![hahouari-inno-setup](https://img.shields.io/badge/@hahouari-Inno_Setup-blue)

CLI tool that simplifies bundling flutter apps into Windows installers using Inno Setup.

# Guide

## 1. Install `inno_bundle` package into your project

```sh
dart pub add dev:inno_bundle
```

## 2. Build the Installer

Run the build command on release mode

```sh
dart run inno_bundle
```

**Note:** This will generate the initial configuration if not present in your `pubspec.yaml`.

# More Options and Examples

You can find detailed documentation on customizing `inno_bundle`, including examples, on the [GitHub wiki pages](https://github.com/hahouari/inno_bundle/wiki).

To configure your installer, see [Configuration Options](https://github.com/hahouari/inno_bundle/wiki/Configuration-Options), and if you need other use cases with our CLI tool, look up [CLI Options](https://github.com/hahouari/inno_bundle/wiki/CLI-Tool-Options).

# Using GitHub Workflow?

To automate the process of building the installer with GitHub Actions, refer to [this demo](https://github.com/hahouari/flutter_inno_workflows_demo).

You can copy the [build.yaml](https://github.com/hahouari/flutter_inno_workflows_demo/blob/dev/.github/workflows/build.yaml) file into your project and make sure to update [the push branch](https://github.com/hahouari/flutter_inno_workflows_demo/blob/fb49da23996161acc80f0e9f4c169a01908a29a7/.github/workflows/build.yaml#L5). This setup will build the installer and publish it to [GitHub Releases](https://github.com/hahouari/flutter_inno_workflows_demo/releases) with the appropriate versioning.

# DLL Files Handling

`inno_bundle` handles including all necessary DLL files within the installer. For more info, refer to [this page](https://github.com/hahouari/inno_bundle/wiki/Handling-Missing-DLL-Files).

# Reporting Issues

If you encounter any issues <a href="https://github.com/hahouari/inno_bundle/issues" target="_blank">please report them here</a>.
