## 0.0.1

- Add a working bundler and example.

## 0.0.2

- Add a README.md to example and update main README.md.

## 0.0.3

- Fix `languages` attribute name in README.md example.

## 0.1.0

- Make `installer_icon` optional attribute.

## 0.1.1

- Update README.md.

## 0.2.0

- Update default icon, old one is not premissable to use for commercial use
  without license, so I created new one from **license free** resources.

- Clean cuportino icons from example as it is unused.

- Clean `lib\inno_bundle.dart` and `test\inno_bundle_test.dart`.

- When default icon is used, the new one is copied to `%TEMP%` folder on every
  installer build, I did not find an efficient way to update the old one.
