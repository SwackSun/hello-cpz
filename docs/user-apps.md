# Build, install and publish hello-cpz

Run the host commands from the example directory containing `CMakeLists.txt`, `src/` and `scripts/`. If you received the source kit, copy it into your own working directory first. In the firmware repository, edit `app/hello-cpz/`. Re-exporting replaces the contents of `github/release_app/hello-cpz/`.

## 1. Set up Ubuntu and Buildroot

On Ubuntu 26.04, run the setup script as a regular user. It uses sudo to install host packages. The first build needs an internet connection. Choose a Linux build path without spaces.

```sh
./scripts/install-dev-env.sh --ubuntu 26.04
```

The Ubuntu version is required. When run interactively without arguments, the script prompts with `Ubuntu version [26.04]`. Press Enter to select 26.04, the currently supported version. For unattended setup, pass `--ubuntu 26.04`.

The script downloads and verifies the pinned Buildroot source and uses `scripts/hello_defconfig` to build a Cortex-A53 AArch64 glibc toolchain with Linux 6.18 series headers. The build script uses the resulting `sdk-work/output/` directory. If setup is interrupted, rerun the same command to reuse the download cache and build directory. [Pinned Buildroot source](https://codeload.github.com/buildroot/buildroot/tar.gz/8b238854d909c9cce32ef9671d968b03e323b55d) · [Buildroot downloads](https://buildroot.org/download.html)

If you already have a matching czlite SDK, run `export CM0_BUILDROOT_OUTPUT=/absolute/path/to/buildroot/output` before setup to reuse it. To check host dependencies, run `./scripts/install-dev-env.sh --ubuntu 26.04 --check`.

## 2. Build and package

```sh
./scripts/build.sh
file out/device/usr/bin/hello-cpz
./scripts/package.sh
ipk="dist/hello-cpz_$(cat VERSION)_aarch64.ipk"
sha256sum "$ipk"
```

Check that `file` reports ARM aarch64. Edit `src/main.c` for application logic, `USAGE.md` for the on-device help, and `description.txt` for the English store summary (1–49 printable ASCII characters on one line). Rebuild after changing the app or help. The IPK includes the MIT notice at `/usr/share/licenses/hello-cpz/LICENSE`.

Packaging reads `VERSION`. If a different package already exists for that revision, choose the next revision in `VERSION` and package again. You can still pass a version explicitly, for example `./scripts/package.sh 1.0-4`. A changed version also gives opkg a way to recognize an upgrade.

## 3. Install and run on CardputerZero

From Bash on Ubuntu, enter the IP address shown on your CardputerZero. These commands copy the package and open a device shell. The uppercase `-O` selects the SCP protocol supported by the developer image.

```sh
read -rp 'CardputerZero IP address: ' device
scp -O "dist/hello-cpz_$(cat VERSION)_aarch64.ipk" "root@${device}:/tmp/"
ssh "root@${device}"
```

In the device shell, run the following for revision `1.0-3` on czlite v0.3.8-rc.1. If you changed the revision, use the filename printed by the packaging script.

```sh
opkg install /tmp/hello-cpz_1.0-3_aarch64.ipk
cpz list --installed
~/app/hello-cpz
```

The package list should include `hello-cpz - 1.0-3`. In fff, select `~/app/hello-cpz` and press Enter. The app displays `Hello from CardputerZero!` and waits for a second Enter to return to the file list. The same prompt appears in an interactive shell. With redirected input or output the program prints the greeting and exits immediately.

The launcher points to `/usr/bin/hello-cpz`. If `readlink /etc/opkg/cpz.conf` prints `../cpz.conf`, opkg, cpz and cpz-store share the preinstalled package database at `/usr/lib/opkg/status`.

On **v0.3.7**, use `opkg -f /etc/cpz.conf install /tmp/hello-cpz_1.0-3_aarch64.ipk`. On that release plain opkg writes to `/var/lib/opkg/status`, while cpz reads the other database.

## 4. Upload manually and submit for review

1. Return to the Ubuntu shell with `exit` if you are connected over SSH. Use the developer account that owns the package name. Run the upload script from the source kit. Enter your developer email and password when prompted. Password input is hidden. The script saves the package as a draft under your account and keeps the login credentials in process memory.

   ```sh
   ./scripts/upload.py "dist/hello-cpz_$(cat VERSION)_aarch64.ipk"
   ```

2. Sign in to the publishing dashboard. Check the package name `hello-cpz`, version, category `app` and English description, then submit the draft for review. You can also select the IPK and save a draft directly from the dashboard. [CPZ publishing dashboard](https://cpz.firmiss.com/admin/packages/)

3. After approval, run `cpz update` and `cpz install hello-cpz` on a device using the official CPZ feed. Launch it with `~/app/hello-cpz`.

To submit through MCP, give your connected agent the IPK path and version. [MCP publishing instructions](mcp-agent.md)
