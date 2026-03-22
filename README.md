# Citronics Lime Kernel Images

Builds `.deb` packages for relevant kernel versions to be used on the Citronics Lime (Fairphone 2) board.

## Prerequisites

```
sudo apt-get install build-essential libncurses-dev bison flex libssl-dev bc fakeroot git libelf-dev
```

For cross-compilation from x86/amd64:

```
sudo apt-get install gcc-arm-linux-gnueabihf
```

## Building

Initialize the kernel submodule, tag the commit, and run the build script:

```
git submodule update --init
git tag v1.1
sudo ./build-all-kernels.sh
```

This produces `linux-image` and `linux-headers` `.deb` packages in `output/<branch>/`. Debug and `linux-libc-dev` packages are automatically excluded.

## Releasing

To build and publish a release to GitHub in one step:

```
git tag v1.1
git push origin v1.1
sudo ./release.sh
```

`release.sh` calls `build-all-kernels.sh`, then uploads the image and headers `.deb` files to a GitHub Release. After releasing, trigger the [deb-packages](https://github.com/Citronics/deb-packages) workflow to update the APT repository.

Note: kernel compilation requires significant time and resources. You need a cross-compilation toolchain if not building on armhf natively.
