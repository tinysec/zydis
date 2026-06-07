# zydis

[![build](https://github.com/tinysec/zydis/actions/workflows/ci.yaml/badge.svg)](https://github.com/tinysec/zydis/actions)
[![package](https://img.shields.io/badge/package-FetchContent-blue)](#use-from-another-cmake-project)

## Introduction

`zydis` packages Zydis 4.1.1 as a standalone CMake static library.
The repository contains the required Zycore 1.5.2 source as normal files, so
there are no submodules, nested Git repositories, or configure-time downloads.

The exported CMake target is:

```cmake
zydis::zydis
```

Linking this target adds the Zydis and Zycore include directories to consumers:

```c
#include <Zydis/Zydis.h>
```

## Build

```powershell
cmake -S . -B build -DZYDIS_INSTALL=ON
cmake --build build --config Release
cmake --install build --prefix install
```

## WDK 7 Build

Open a normal command prompt and enter the WDK 7 environment first. The
toolchain file expects `setenv.bat` to select the WDK compiler and paths.

```bat
call C:\WinDDK\7600.16385.1\bin\setenv.bat C:\WinDDK\7600.16385.1 fre x86 WIN7 no_oacr
cmake -S . -B build-wdk7-x86 -G "NMake Makefiles" ^
  -DCMAKE_TOOLCHAIN_FILE=cmake\toolchains\wdk7.cmake ^
  -DZYDIS_KERNEL_MODE=ON ^
  -DZYDIS_WDK7_COMPAT=ON ^
  -DZYDIS_INSTALL=ON
cmake --build build-wdk7-x86
```

Use `x64` instead of `x86` in the `setenv.bat` command for an AMD64 build.
`ZYDIS_WDK7_COMPAT=ON` selects the WDK 7 compatible no-libc minimal decoder
profile. It enables `ZYAN_NO_LIBC`, `_KERNEL_MODE`, `/GS-`, and `/Zl`, and
disables encoder/formatter sources that require newer compiler support.

## Use From Another CMake Project

Use `FetchContent` and pin a tag:

```cmake
include(FetchContent)

FetchContent_Declare(
    zydis
    GIT_REPOSITORY https://github.com/tinysec/zydis.git
    GIT_TAG v4.1.1)
FetchContent_MakeAvailable(zydis)

target_link_libraries(your_target PRIVATE zydis::zydis)
```

## License

Zydis is distributed under the MIT license in `LICENSE`.
The vendored Zycore MIT license is preserved in `THIRD_PARTY_LICENSES/`.
