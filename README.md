# zydis

[![CI](https://github.com/tinysec/zydis/actions/workflows/ci.yaml/badge.svg)](https://github.com/tinysec/zydis/actions)
[![version](https://img.shields.io/badge/version-4.1.1-blue)](https://github.com/tinysec/zydis/releases/tag/v4.1.1)

## Introduction

A CMake build of [Zydis](https://github.com/zyantific/zydis) 4.1.1 (with Zycore)
that builds with both the modern MSVC / GCC / Clang toolchains and the legacy
WDK 7 (VC9 / MSVC 15.0) toolchain, in its full decoder + formatter configuration.

It can be consumed two ways:

- **From source** as a local CMake dependency (`FetchContent` / `add_subdirectory`),
  exposing the `Zydis::Zydis` / `Zycore::Zycore` targets. No install / `find_package`.
- **Prebuilt**, by downloading the release archive that matches your toolchain,
  architecture, link type and CRT.

## Features

- Zydis 4.1.1 + Zycore, plain source, no submodules.
- Builds with modern MSVC / GCC / Clang and with WDK 7 (VC9).
- Full decoder and formatter (also under WDK 7).
- Static or shared library (`BUILD_SHARED`), x86 and x64.
- Configurable MSVC runtime (`CMAKE_MSVC_RUNTIME_LIBRARY`): `/MT` or `/MD`.

## Use from source (FetchContent)

Builds Zydis from source and exposes `Zydis::Zydis`. Static library by default:

```cmake
include(FetchContent)
FetchContent_Declare(
    zydis
    GIT_REPOSITORY https://github.com/tinysec/zydis.git
    GIT_TAG v4.1.1)
FetchContent_MakeAvailable(zydis)

target_link_libraries(your_target PRIVATE Zydis::Zydis)
```

Build options (set before `FetchContent_MakeAvailable`):

- `set(BUILD_SHARED ON)` — build the shared library (DLL + import lib).
- `set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")` — `/MT`
  (static CRT, no VC++ redistributable); the default is `/MD`.

Standalone builds:

```sh
cmake -S . -B build                     # static
cmake -S . -B build -DBUILD_SHARED=ON   # shared (DLL + import lib)
cmake --build build --config Release
```

## Prebuilt downloads

Each build publishes an immutable release on the 4-part tag `v4.1.1.<build>` and a
rolling release on the 3-part tag `v4.1.1` that always tracks the latest build.
The rolling release's asset names omit the build number, so the download URLs are
stable, for example:

```
https://github.com/tinysec/zydis/releases/download/v4.1.1/zydis-msvc-x64-static-mt.zip
```

Pick the archive that matches your build:

| Toolchain | Archive name | Notes |
|-----------|--------------|-------|
| Modern MSVC | `zydis-msvc-<arch>-shared.zip` | DLL + import lib, self-contained (`/MT`) |
| Modern MSVC | `zydis-msvc-<arch>-static-mt.zip` | static lib, `/MT` (no VC++ redistributable) |
| Modern MSVC | `zydis-msvc-<arch>-static-md.zip` | static lib, `/MD` (dynamic CRT) |
| WDK 7 (VC9) | `zydis-wdk7-<arch>-static.zip` | static lib for the WDK 7 toolchain |
| WDK 7 (VC9) | `zydis-wdk7-<arch>-shared.zip` | DLL + import lib for the WDK 7 toolchain |

`<arch>` is `x64` or `x86`. Each archive contains `lib/` (and `bin/` for shared),
the `include/` headers, and `LICENSE`. A static library's CRT must match your
project, so choose `-static-mt` for `/MT` projects and `-static-md` for `/MD`.
