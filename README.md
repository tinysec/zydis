# wdk-zydis

[![build](https://github.com/tinysec/wdk-zydis/actions/workflows/ci.yaml/badge.svg)](https://github.com/tinysec/wdk-zydis/actions)
[![version](https://img.shields.io/badge/version-4.1.1-blue)](https://github.com/tinysec/wdk-zydis/releases/tag/v4.1.1)

## Introduction

A CMake build of [Zydis](https://github.com/zyantific/zydis) 4.1.1 (with Zycore)
that compiles with the legacy WDK 7 (VC9 / MSVC 15.0) toolchain in its full
decoder + formatter configuration. Consumed as a local CMake dependency
(`FetchContent` / `add_subdirectory`); no install or `find_package`.

## Features

- Zydis 4.1.1 + Zycore, plain source, no submodules.
- Builds with WDK 7 (VC9) and modern MSVC / GCC / Clang.
- Full decoder and formatter under WDK 7.
- Static or shared library (`BUILD_SHARED_LIBS`), x86 and x64.

## Usage

Add it as a local dependency and link `Zydis::Zydis`:

```cmake
include(FetchContent)
FetchContent_Declare(
    zydis
    GIT_REPOSITORY https://github.com/tinysec/wdk-zydis.git
    GIT_TAG v4.1.1)
FetchContent_MakeAvailable(zydis)

target_link_libraries(your_target PRIVATE Zydis::Zydis)
```

Static library (default):

```sh
cmake -S . -B build
cmake --build build
```

Shared library (DLL + import lib):

```sh
cmake -S . -B build -DBUILD_SHARED_LIBS=ON
cmake --build build
```
