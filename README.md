# Citronics Lime Kernel Images

Builds `.deb` packages for multiple kernel sources to be used on the Citronics Lime (Fairphone 2) board.

## Prerequisites

```
sudo apt-get install build-essential libncurses-dev bison flex libssl-dev bc fakeroot git libelf-dev
```

For cross-compilation from x86/amd64:

```
sudo apt-get install gcc-arm-linux-gnueabihf
```

## Kernel Sources

Kernel sources are defined in `kernels.conf`. Each line specifies a kernel name, repository URL, and branch:

```
msm8974-6.12.y  https://github.com/msm8974-mainline/linux  qcom-msm8974-6.12.y
msm8x74-6.15.y  https://github.com/mlainez/linux-msm8x74   staging
```

Each entry must have a matching config file in `configs/<name>.config`.

## Building

Tag the commit and run the build script:

```
git tag v2.0
./build-all-kernels.sh
```

This clones/fetches each kernel source into `sources/`, builds with the matching config, and produces `linux-image` and `linux-headers` `.deb` packages in `output/<name>/`. Debug and `linux-libc-dev` packages are automatically excluded.

To build a single kernel only:

```
./build-all-kernels.sh msm8x74-6.15.y
```

## Adding a New Kernel

1. Add a line to `kernels.conf` with the name, repo URL, and branch
2. Create a matching config file in `configs/<name>.config`
3. Run `./build-all-kernels.sh <name>` to test the build

## Releasing

To build and publish a release to GitHub in one step:

```
git tag v2.0
git push origin v2.0
./release.sh
```

To build and release only a specific kernel:

```
./release.sh msm8x74-6.15.y
```

`release.sh` calls `build-all-kernels.sh`, then uploads the image and headers `.deb` files to a GitHub Release. After releasing, trigger the [deb-packages](https://github.com/Citronics/deb-packages) workflow to update the APT repository:

```
gh workflow run update-repo.yml --repo Citronics/deb-packages
```

Note: kernel compilation requires significant time and resources. You need a cross-compilation toolchain if not building on armhf natively.
