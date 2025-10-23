# AUR Packaging for the Helium Browser

This is the public version of the AUR package `helium-browser-bin` for the Helium Browser. The prebuilt binaries are published at [imputnet/helium-linux](https://github.com/imputnet/helium-linux).

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [AUR Packaging for the Helium Browser](#aur-packaging-for-the-helium-browser)
  - [Goals](#goals)
  - [Licensing Compliance](#licensing-compliance)
  - [Understanding the `PKGBUILD`](#understanding-the-pkgbuild)
    - [`prepare()`](#prepare)
      - [Inclusion Rationale](#inclusion-rationale)
    - [`package()`](#package)
      - [Disable user-local desktop generation in chrome-wrapper](#disable-user-local-desktop-generation-in-chrome-wrapper)
        - [Inclusion Rationale](#inclusion-rationale-1)
      - [Install a simple wrapper](#install-a-simple-wrapper)
        - [Inclusion Rationale](#inclusion-rationale-2)
      - [Adding `helium-browser-flags.conf` support](#adding-helium-browser-flagsconf-support)
        - [Expected Formats](#expected-formats)
        - [Verification](#verification)
        - [Inclusion Rationale](#inclusion-rationale-3)
  - [Cheers](#cheers)

<!-- markdown-toc end -->

## Goals

1.  Faithfully reproduce upstream while adding expected packaging-level integrations only (e.g., flags file support).
2.  Insure developer (or other maintainer) takeover is smooth.
3.  Packaging is suitable for official Arch repository adoption.
4.  Relay relevant feedback and bug reports upstream.
5.  Users should be able to understand the `PKGBUILD`.

## Licensing Compliance
To be suitable for official repo adoption, `PKGBUILD` and source licensing needs to be clearly identified. For guidance, see [Arch Wiki Package Guidelines](https://wiki.archlinux.org/title/Arch_package_guidelines#Licenses).
- [ ] Arch Package Guidelines 11.1 compliance
    - [x] License Helium Browser.
    - [ ] License Ungoogled Chromium's build process.
- [x] Arch Package Guidelines 11.2 compliance
    - [x] `REUSE` compliance
    - Since `v0.4.7.1`
    - Verification: `pkgctl license check`

## Understanding the `PKGBUILD`

### `prepare()`

Here, we adjust the upstream `helium.desktop` file simply by appending `browser`, or some variation of it.

``` bash
# Fix upstream desktop file to use the correct name
sed -i \
-e 's/Exec=chromium/Exec=helium-browser/' \
-e 's/Name=Helium$/Name=Helium Browser/' \
-e 's/Icon=helium/Icon=helium-browser/' \
"${srcdir}/helium.desktop"
```

#### Inclusion Rationale

Avoid naming and icon clashes, and point `Exec` to our wrapper script.

### `package()`

#### Disable user-local desktop generation in chrome-wrapper

This was contributed by Pujan Modha in PR #1. It patches the installed `chrome-wrapper` so no stray `chromium-devel.desktop` file gets written to `~/.local/share/applications`. This behaviour stems from the upstream build process, but it's not a good user experience. For a full discussion on this see [PR #1](https://github.com/s6muel/helium-browser-bin/pull/1).

``` bash
sed -i 's/exists_desktop_file || generate_desktop_file/true/' \
"$pkgdir/opt/${pkgname}/chrome-wrapper"
```

##### Inclusion Rationale

Establishes expected end user behaviour \[i.e., no unexpected entries in application runners\].

#### Install a simple wrapper

In our `prepare()` function we added `Exec=helium-browser` to our `.desktop` file. Now we create the wrapper so the application can accurately resolve its `PATH` and environment. In short, this makes sure that execution of the `helium.desktop` from an application runner is robust. For a full discussion, see [PR \#1](https://github.com/s6muel/helium-browser-bin/pull/1).

``` bash
    install -dm755 "${pkgdir}/usr/bin"
    # We write the output of Line 101 into a script at
    # /usr/bin/helium-browser
    cat > "${pkgdir}/usr/bin/${_binaryname}" << 'EOF'
#!/usr/bin/env bash
...
exec /opt/helium-browser-bin/chrome-wrapper "${FLAGS[@]}" "$@"
EOF
    # Now we make sure we can execute the script that our
    # .desktop file expects in its Exec= line.
    chmod 755 "${pkgdir}/usr/bin/${_binaryname}"
```

##### Inclusion Rationale

It's good when we can run applications ;).

#### Adding `helium-browser-flags.conf` support

This adds support for system and user flags in `.conf` files using `/etc/helium-browser-flags.conf` and `$XDG_CONFIG_HOME/helium-browser-flags.conf` respectively. Setting flags in the environment is also supported via `$HELIUM_USER_FLAGS`.

A user on the AUR [commented](https://aur.archlinux.org/packages/helium-browser-bin#comment-1044045) that the expected behaviour of parsing `*-flags.conf` on startup for Helium was non-existent. This is a packaging feature specific to Arch and included with the `chromium` package.

The [official Arch PKGBUILD for Chromium](https://gitlab.archlinux.org/archlinux/packaging/packages/chromium/-/blob/main/PKGBUILD?ref_type=heads) implements persistent flags via a small `C` based launcher (`chromium-launcher`) that reads `/etc/chromium-flags.conf` and `$XDG_CONFIG_HOME/chromium-flags.conf`, parses each non-comment line, and appends the resulting arguments on startup.

The parser honours quoting and escaping, but does not allow command substitution (i.e., `--flag=$(rm -rf /)` or `` --flag=`cat /etc/passwd` ``), variable expansion (i.e., `$HOME` will not expand and is ignored), globbing, or expansion of `~`.

We reproduce this behaviour in `bash` for `helium-browser-bin` as follows:

- Lines with `$(..)` or `` `backticks` `` are ignored to block command substitution.
- `$VARS` and `~` are not expanded and passed literally.
- Globbing is disabled during `eval`.
- Comments and blank lines ignored.

A `bash` implementation has been chosen to minimise dependencies and maintainer overhead. It has been tested successfully as of October 20, 2025.

``` bash
# Fails on errors or unreadable commands
set -euo pipefail

# Gather our config path
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"

# Get system flags path
SYS_CONF="/etc/helium-browser-flags.conf"
# Get user flags path
USR_CONF="${XDG_CONFIG_HOME}/helium-browser-flags.conf"

FLAGS=()

append_flags_file() {
    local file="$1"
    [[ -r "$file" ]] || return 0
    local line safe_line
    # Filter comments & blank lines
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
        # Sanitise: block command substitution; prevent $VAR and ~ expansion
        case "$line" in
            *'$('*|*'`'*)
                echo "Warning: ignoring unsafe line in $file: $line" >&2
                continue
                ;;
        esac
        # Disable globbing during eval
        set -f
        # Prevent $VAR and ~ expansion while allowing eval to parse quotes & escapes
        safe_line=${line//$/\\$}
        safe_line=${safe_line//~/\\~}
        eval "set -- $safe_line"
        # Enable globbing for rest of the script
        set +f
        for token in "$@"; do
            FLAGS+=("$token")
        done
    done < "$file"
}

append_flags_file "$SYS_CONF"
append_flags_file "$USR_CONF"

# Add environment var $HELIUM_USER_FLAGS
if [[ -n "${HELIUM_USER_FLAGS:-}" ]]; then
    # Split env contents on whitespace; users can quote if needed.
    read -r -a ENV_FLAGS <<< "$HELIUM_USER_FLAGS"
    FLAGS+=("${ENV_FLAGS[@]}")
fi

# Append flags to exec
exec /opt/helium-browser-bin/chrome-wrapper "${FLAGS[@]}" "$@"
EOF
```

##### Expected Formats

**`.conf`**
-  Single Line
    ``` conf
    --your-flag --another-flag="with values"
    ```
-  Multi Line
    ``` conf
    --your-flag
    --another-flag="with values"
    ```
**Environment**
- Single line only, split on white space, quotes are supported.
    ``` bash
    export HELIUM_USER_FLAGS=--your-flags="with values" --just-flag-it
    ```

##### Verification

Open `helium://version` and check the *Command Line* entry. It should represent your flags.

##### Inclusion Rationale

Arch users expect to be able to apply flags via `~/.config/*-flags.conf`.

## Cheers

- @imputnet and the [Helium Project](https://github.com/imputnet/helium) for developing a great browser.
- @pujan-modha for contributing a robust wrapper mechanism and for providing insight into upstream mechanics.
- AUR user `networkException` for maintaining [Ungoogled Chromium on the AUR](https://aur.archlinux.org/packages/ungoogled-chromium-bin) and saving me a bunch of time in establishing the Helium package.
- AUR user `init_harsh` for their bash contributions which inspired the `helium-browser-flags.conf` support and [raising the issue originally](https://aur.archlinux.org/packages/helium-browser-bin#comment-1044045).
- @foutrelis for writing the [chromium-launcher](https://github.com/foutrelis/chromium-launcher).
