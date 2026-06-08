# wdk-zydis

[![build](https://github.com/tinysec/wdk-zydis/actions/workflows/ci.yaml/badge.svg)](https://github.com/tinysec/wdk-zydis/actions)
[![version](https://img.shields.io/badge/version-4.1.1-blue)](https://github.com/tinysec/wdk-zydis/releases/tag/v4.1.1)
[![cmake](https://img.shields.io/badge/CMake-package-064f8c)](#cmake-usage)

## Introduction

`wdk-zydis` is a standalone CMake package for Zydis 4.1.1. It builds Zydis and
Zycore as static libraries and exports the `zydis::zydis` CMake target for
downstream projects.

## Features

- Zydis 4.1.1 packaged as a static CMake library.
- Zycore 1.5.2 included as regular source files.
- No Git submodules or configure-time dependency downloads.
- Installable CMake package with `find_package(zydis CONFIG REQUIRED)`.
- WDK 7 compatible kernel-mode build profile.

## CMake Usage

Use `FetchContent`:

```cmake
include(FetchContent)

FetchContent_Declare(
    zydis
    GIT_REPOSITORY https://github.com/tinysec/wdk-zydis.git
    GIT_TAG v4.1.1)
FetchContent_MakeAvailable(zydis)

target_link_libraries(your_target PRIVATE zydis::zydis)
```

Use an installed package:

```cmake
find_package(zydis 4.1.1 CONFIG REQUIRED)

target_link_libraries(your_target PRIVATE zydis::zydis)
```
