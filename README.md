# Ladybird Browser AppImage

This repository provides automated, weekly AppImage builds for the [Ladybird Web Browser](https://ladybird.org/), compiled directly from the latest upstream `main` branch.

This project is a fork based on the original work by [pkgforge-dev](https://github.com/pkgforge-dev). It was created to restore and maintain a fully functional CI/CD build pipeline after the upstream packaging builds had been broken for several months.

## 🌟 Key Improvements & Features

* **Patch-Free Upstream Build:** Dropped all legacy downstream code patches. The build pipeline compiles clean, unpatched Ladybird source code directly from upstream, avoiding fragile breakages.

* **Accelerated CI Builds:** Implemented dual compiler caching using `sccache` (for Rust) and `ccache` (for C++), persisting across GitHub Actions workflow runs to drastically reduce build times.

* **Vulkan Hardware Acceleration:** Built with complete Vulkan header support (`vulkan-devel`) for modern GPU-driven rendering and fast, low-CPU video playback.

* **Bypassed  Tests:** Configured with `-DBUILD_TESTING=OFF` to bypass non-essential unit-test compilation errors (such as GCC 14 `-Wrestrict` warnings) and speed up binary packaging.

* **Automated Weekly Releases:** GitHub Actions automatically compiles and publishes a fresh AppImage every week via cron schedule.

## 🚀 How to Use the AppImage

AppImages are single-file executables that bundle the browser and its core dependencies. They run on most modern Linux distributions without installation.

### 1. Download

Go to the [**Releases**](../../releases) page of this repository and download the latest `.AppImage` file.

### 2. Make it Executable

Open your terminal in the download folder and grant execution permissions:

```
chmod +x Ladybird-*.AppImage

```

### 3. Run

Launch Ladybird directly from your terminal or file manager:

```
./Ladybird-*.AppImage

```

## 🤝 Credits & Acknowledgments

* **Original Packaging Base:** [pkgforge-dev](https://github.com/pkgforge-dev) for the initial AppImage packaging scripts.

* **Ladybird Team:** [Ladybird Browser Initiative](https://github.com/LadybirdBrowser/ladybird) for building a brand-new, truly independent web engine.
