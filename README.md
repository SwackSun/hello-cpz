# hello-cpz

A small C app for CardputerZero running czlite. Open `~/app/hello-cpz` in fff to display `Hello from CardputerZero!`. Press Enter to return to the file list.

## Build your first package

On Ubuntu 26.04, open a terminal in the copy of this kit where you want to develop. Run setup once, then build and package the app.

```sh
./scripts/install-dev-env.sh --ubuntu 26.04
./scripts/build.sh
./scripts/package.sh
```

The last command prints the path to the ARM64 IPK in `dist/`. To try a change, edit `src/main.c`. You can preview the greeting immediately on Ubuntu with a C compiler, even before building the device toolchain.

```sh
mkdir -p out
cc -Wall -Wextra src/main.c -o out/hello-host
./out/hello-host
```

Run `./scripts/build.sh` again for the device. The package revision lives in `VERSION`. Bump it when packaging changed contents after a previous build of the same revision.

## Install and publish

Follow the [developer manual](docs/user-apps.md) to copy the IPK to the device, install it with opkg, verify it in fff and submit it for review. It covers SDK reuse and czlite v0.3.7 as well. For an agent submitting through CPZ, use the [MCP publishing instructions](docs/mcp-agent.md).

## License

The hello-cpz example, its scripts and its documentation use the [MIT License](LICENSE). Buildroot and the toolchain components downloaded during setup carry their own licenses.
