# elementary App Template

_a template to develop Apps for [elementary OS](https://elementary.io/) and its AppCenter_

This template is based on the official [elementary Developer Documentation](https://docs.elementary.io/develop/). Simply download it and your ready to hack!

## Table of Contents

- [Prerequisites](#prerequisites)
- [Build System](#build-system)
- [Translations](#translations)
- [Icons](#icons)
- [Packaging](#packaging)
- [Testing](#testing)

## Prerequisites

This app template assumes you installed the following as documented in [The Basic Setup of the elementary Developer Documentation](https://docs.elementary.io/develop/writing-apps/the-basic-setup):

- Development Libraries (`elementary-sdk`)
- elementary Flatpak Platform and Sdk (`io.elementary.Platform` and `io.elementary.Sdk`)

## Build System

The Build System is preconfigured an ready to use according to [The Build System described in the elementary Developer Documentation](https://docs.elementary.io/develop/writing-apps/our-first-app/the-build-system).

### Compile, Install and Start

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.github.alainm23.planify`

    sudo ninja install
    io.github.ellie_commons.byte

### Uninstall

Execute the following command to remove the app template's binary from your system:

```bash
sudo ninja uninstall
```

## Translations

This template is fully translatable and everything is setup as described in the [Translations section of the elementary Developer Documentation](https://docs.elementary.io/develop/writing-apps/our-first-app/translations)'

### Update translations

Remember that each time you add new translatable strings or change old ones, you should regenerate your `*.pot` and `*.po` files using the `*-pot` and `*-update-po` build targets from the previous two steps as follows:

```bash
ninja io.github.ellie_commons.byte-pot
ninja io.github.ellie_commons.byte-update-po
```

### Add more languages

If you want to support more languages, just list them in the LINGUAS file and generate the new po file with the `*-update-po` target:

```bash
ninja -C build io.github.ellie_commons.byte-update-po
```

## Icons

Support for icons is configured too according to the [Icons section of the elementary Developer Documentation](https://docs.elementary.io/develop/writing-apps/our-first-app/icons).

## Packaging

Support for Flatpak is builtin as well and setup according to the [Packaging section of the elementary Developer Documentation](https://docs.elementary.io/develop/writing-apps/our-first-app/packaging).

### Compile, Package and Install

To run a test build and install your app, you can execute flatpak-builder from the project root:

```bash
flatpak-builder build io.github.ellie_commons.byte.yml --user --install --force-clean --install-deps-from=appcenter
```

Then execute with

```bash
flatpak run io.github.ellie_commons.byte
```

### Uninstall

```bash
flatpak uninstall io.github.ellie_commons.byte --user
```