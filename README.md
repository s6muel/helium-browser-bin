# AUR Packaging for the Helium Browser

This is the public version of the AUR package `helium-browser-bin` for the Helium Browser. The prebuilt binaries are published at [imputnet/helium-linux](https://github.com/imputnet/helium-linux).

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [AUR Packaging for the Helium Browser](#aur-packaging-for-the-helium-browser)
- [Goals](#goals)
- [Licensing Compliance](#licensing-compliance)
- [Understanding the `PKGBUILD`](#understanding-the-pkgbuild)
  - [Sources](#sources)
    - [`helium-browser.sh`](#helium-browsersh)
  - [`prepare()`](#prepare)
    - [Get architecture specific directory](#get-architecture-specific-directory)
      - [Inclusion Rationale](#inclusion-rationale)
    - [Fix upstream `.desktop` File](#fix-upstream-desktop-file)
      - [Inclusion Rationale](#inclusion-rationale-1)
  - [`package()`](#package)
    - [Get architecture specific directory](#get-architecture-specific-directory-1)
      - [Inclusion Rationale](#inclusion-rationale-2)
    - [Install a simple wrapper](#install-a-simple-wrapper)
      - [Inclusion Rationale](#inclusion-rationale-3)
- [Reviewing the wrapper (`helium-browser.sh`)](#reviewing-the-wrapper-helium-browsersh)
  - [Adding `helium-browser-flags.conf` support](#adding-helium-browser-flagsconf-support)
    - [Expected Formats](#expected-formats)
      - [`.conf`](#conf)
        - [Single Line](#single-line)
        - [Multi Line](#multi-line)
      - [Environment](#environment)
    - [Verification](#verification)
    - [Inclusion Rationale](#inclusion-rationale-4)
  - [Set environment variables for Helium](#set-environment-variables-for-helium)
    - [`CHROME_WRAPPER`](#chrome_wrapper)
    - [`CHROMIUM_VERSION_EXTRA`](#chromium_version_extra)
  - [Sanitise std{in,out,err}](#sanitise-stdinouterr)
  - [Execute the binary](#execute-the-binary)
  - [Previous version and `diff`](#previous-version-and-diff)
- [Cheers](#cheers)

<!-- markdown-toc end -->


# Goals

1.  Faithfully reproduce upstream while adding expected packaging-level integrations only (e.g., flags file support).
2.  Insure developer (or other maintainer) takeover is smooth.
3.  Packaging is suitable for official Arch repository adoption.
4.  Relay relevant feedback and bug reports upstream.
5.  Users should be able to understand the `PKGBUILD`.


# Licensing Compliance

To be suitable for official repo adoption, `PKGBUILD` and source licensing needs to be clearly identified. For guidance, see [Arch Wiki Package Guidelines](https://wiki.archlinux.org/title/Arch_package_guidelines#Licenses)

-   [X] Arch Package Guidelines 11.1 compliance
    -   [X] License Helium Browser
    -   [X] License Ungoogle Chromium's build process
        -   Since `v0.6.4.1`
-   [X] Arch Package Guidelines 11.2 compliance
    -   [X] `REUSE` compliance
        -   Since `v0.4.7.1`
        -   Verification: `pkgctl license check`


# Understanding the `PKGBUILD`


## Sources


### `helium-browser.sh`

After Helium version `0.7.7.1` the wrapper creation logic was moved out of the PKGBUILD and into a standalone, prepackaged script. This simplifies the PKGBUILD while insuring a more robust install process:

-   Installation no longer depends on successful `cat` write during install,
-   Wrapper is now included in `source` and `sha256shums`, making any changes explicit and easier to audit (i.e., nefarious tampering).

Additionally there's no need to use `set -euo pipefail` since we utilise a prepackaged artifact, so that was removed in this version. For more details on the wrapper's internals and any changes made, see the [reviewing the wrapper](#reviewing-the-wrapper-helium-browsersh) section.


## `prepare()`


### Get architecture specific directory

Since including the upstream `aarch64` tarball in `0.6.4.1`, we need to differentiate between architectures to insure `makepkg` works from the correct directories. We therefore utilise `$CARCH` to return the working system architecture and assign it to the `_archdir` variable.

This adjustment exists to ensure upstream's naming of `arm64` matches the GNU Linux Multiarch Archtecture Specifier of `aarch64` as returned by `$CARCH` on said systems. For reference, see <https://wiki.debian.org/Multiarch/Tuples>

```bash
# Get architecture specific directory
_archdir="${_pkgname}-${pkgver}-$([[ $CARCH == "aarch64" ]] && echo "arm64" || echo "x86_64")_linux"
```


#### Inclusion Rationale

Installations will break without this variable.


### Fix upstream `.desktop` File

Here, we adjust the upstream `helium.desktop` file simply by appending `browser`, or some variation of it, e.g., `Helium -> Helium Browser`.

```bash
# Fix upstream desktop file to use the correct name
sed -i \
-e 's/Exec=chromium/Exec=helium-browser/' \
-e 's/Name=Helium$/Name=Helium Browser/' \
-e 's/Icon=helium/Icon=helium-browser/' \
"${srcdir}/helium.desktop"
```


#### Inclusion Rationale

Avoid naming and icon clashes, and point `Exec` to our wrapper script.


## `package()`


### Get architecture specific directory

To understand this line, refer to the `prepare()` section. The reason for duplication is that the `prepare()` and `package()` functions operate in separate shells, and do not inherit variables.


#### Inclusion Rationale

Installations will break without this variable.


### Install a simple wrapper

*[Added 2025-12-30.]*

The purpose of the wrapper is to provide an entry point to Helium that parses and applies user/system flags, and executes the Helium binary. The wrapper is thus the target for the `.desktop` entry and shell calls (`gtk-launch helium-browser.desktop`, and `helium-browser` respectively).

Here we simply install the bundled `helium-browser.sh` wrapper to `/usr/bin/helium-browser`.

```bash
# Install a simple wrapper
install -Dm755 "$_binaryname.sh" "$pkgdir/usr/bin/helium-browser"
```


#### Inclusion Rationale

It's good when we can run applications ;).


# Reviewing the wrapper (`helium-browser.sh`)


## Adding `helium-browser-flags.conf` support

This adds support for system and user flags in `.conf` files using `/etc/helium-browser-flags.conf` and `$XDG_CONFIG_HOME/helium-browser-flags.conf` respectively. Setting flags in the environment is also supported via `$HELIUM_USER_FLAGS`.

A user on the [AUR commented](https://aur.archlinux.org/packages/helium-browser-bin#comment-1044045) that the expected behaviour of parsing `*-flags.conf` on startup for Helium was non-existent. This is a packaging feature specific to Arch and included with the `chromium` package.

The [official Arch PKGBUILD for Chromium](https://gitlab.archlinux.org/archlinux/packaging/packages/chromium/-/blob/main/PKGBUILD?ref_type=heads) implements persistent flags via a small `C` launcher (`chromium-launcher`) that reads `/etc/chromium-flags.conf` and `$XDG_CONFIG_HOME/chromium-flags.conf`, parses each non-comment line, and appends the resulting arguments on startup.

The parser honours quoting and escaping, but does not allow command substitution (i.e., `--flag=$(rm -rf /)` or `` --flag=`cat /etc/passwd` ``.), variable expansion (i.e., `$HOME` will not expand and is ignored), globbing, or expansion of `~`.

We reproduce this behaviour in `bash` for `helium-browser-bin` as follows:

-   Lines with `$(..)` or `` `backticks` `` are ignored to block command substitution.
-   `$VARS` and `~` are not expanded and passed literally.
-   Globbing is disabled during `eval`.
-   Comments and blank lines ignored.

A `bash` implementation has been chosen to minimise dependencies and maintainer overhead. It has been tested successfully as of October 20, 2025.

```bash
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

```


### Expected Formats


#### `.conf`


##### Single Line

```conf
--your-flag --another-flag="with values"
```


##### Multi Line

```conf
--your-flag
--another-flag="with values"
```


#### Environment

Single line only, split on white space, quotes are supported.

```bash
export HELIUM_USER_FLAGS=--your-flags="with values" --just-flag-it
```


### Verification

Open `helium://version` and check the *Command Line* entry. It should represent your flags.


### Inclusion Rationale

Arch users expect to be able to apply flags via `~/.config/*-flags.conf`.


## Set environment variables for Helium

These variables were added a result of reproducing the [upstream Chromium wrapper](https://source.chromium.org/chromium/chromium/src/+/main:chrome/installer/linux/common/wrapper) for Linux.


### `CHROME_WRAPPER`

*[Added 2025-12-30.]*

Let's the wrapped binary know that it's been run through the wrapper.

```bash
export CHROME_WRAPPER="`readlink -f "$0"`"
```


### `CHROMIUM_VERSION_EXTRA`

*[Added 2025-12-30.]*

Sets the Chromium version internally to "stable". This also accepts "beta" and "dev".

See: <https://chromium.googlesource.com/chromium/src/+/HEAD/docs/user_data_dir.md#linux>

```bash
export CHROME_VERSION_EXTRA="stable"
```


## Sanitise std{in,out,err}

*[Added 2025-12-30.]*

> Sanitise std{in,out,err} because they'll be shared with untrusted child processes (<http://crbug.com/376567>).

For reference, see <https://codereview.chromium.org/314133003> and <https://issues.chromium.org/issues/40079595>.

```bash
exec < /dev/null
exec > >(exec cat)
exec 2> >(exec cat >&2)
```


## Execute the binary

*[Updated 2025-12-30.]*

Aliasing the binary using `-a "$0"` makes the process appear to Chromium internals as the name of the wrapper, i.e. "helium-browser" in `helium://version`. This doesn't affect Kernel level process naming, i.e. `readlink /proc/$PID/exe` will still return the ultimately executed binary path.

```bash
exec -a "$0" /opt/helium-browser-bin/chrome "${FLAGS[@]}" "$@"
```


## Previous version and `diff`

Refer to the [PKGBUILD for helium `0.7.7.1`](https://github.com/s6muel/helium-browser-bin/blob/8cf3bdcfb8f8f940d41322b82db1b23e98500644/PKGBUILD).

In version `0.7.7.1`, we utilised `cat` to write the wrapper script which erroneously called `chrome-wrapper`. In future versions, the script is prepackaged as an artifact and installed with the PKGBUILD. To review changes made, you can diff lines 74-123 of PKGBUILD version `0.7.7.1` against the latest versions prepackaged script like so:

```diff
> diff <(awk 'NR>=74 && NR<=123' /PATH/TO/OLD/PKGBUILD) helium-browser.sh 
2,4d1
< # Fails on errors or unreadable commands
< set -euo pipefail
< 
50c47,62
< exec /opt/helium-browser-bin/chrome-wrapper "${FLAGS[@]}" "$@"
---
> # Let the wrapped binary know that it has been run through the wrapper.
> export CHROME_WRAPPER="`readlink -f "$0"`"
> 
> # Set Chromium version to 'stable'
> export CHROME_VERSION_EXTRA="stable"
> 
> # Sanitize std{in,out,err} because they'll be shared with untrusted child
> # processes (http://crbug.com/376567).
> exec < /dev/null
> exec > >(exec cat)
> exec 2> >(exec cat >&2)
> 
> # -a "$0" makes the process appear as the name of the wrapper, i.e.
> # 'helium-browser'. This doesn't affect Kernel level process naming.
> exec -a "$0" /opt/helium-browser-bin/chrome "${FLAGS[@]}" "$@"
> 
```


# Cheers

-   @imputnet and the [Helium Project](https://github.com/imputnet/helium) for developing a great browser.
-   @pujan-modha for contributing a robust wrapper mechanism and for providing insight into upstream mechanics.
-   AUR user `networkException` for maintaining [Ungoogled Chromium on the AUR](https://aur.archlinux.org/packages/ungoogled-chromium-bin) and saving me a bunch of time in establishing the Helium package.
-   AUR user `init_harsh` for their bash contributions which inspired the `helium-browser-flags.conf` support and [raising the issue originally](https://aur.archlinux.org/packages/helium-browser-bin#comment-1044045).
-   @foutrelis for writing the [chromium-launcher](https://github.com/foutrelis/chromium-launcher).
