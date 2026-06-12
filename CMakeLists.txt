cmake_minimum_required(VERSION 3.20)

if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.15")
    cmake_policy(SET CMP0091 NEW)
endif()

if(NOT DEFINED ZYDIS_VERSION OR ZYDIS_VERSION STREQUAL "")
    set(ZYDIS_VERSION "4.1.1")
endif()

project(zydis VERSION "${ZYDIS_VERSION}" LANGUAGES C)

# This fork is consumed only as a local CMake dependency (FetchContent /
# add_subdirectory), so it exposes the Zydis::Zydis / Zycore::Zycore targets
# directly. It deliberately does NOT support install()/find_package() - no export
# rules, no generated package config - which keeps the build surface small.

set(_zydis_wdk7_default_mode "")
set(_zydis_wdk7_default_mode_is_kernel OFF)
if(WDK7 AND DEFINED WDK7_DEFAULT_MODE)
    string(TOUPPER "${WDK7_DEFAULT_MODE}" _zydis_wdk7_default_mode)
    if(_zydis_wdk7_default_mode STREQUAL "KERNEL")
        set(_zydis_wdk7_default_mode_is_kernel ON)
    endif()
endif()

set(_zydis_kernel_mode_default OFF)
if(_zydis_wdk7_default_mode_is_kernel)
    set(_zydis_kernel_mode_default ON)
endif()
option(ZYDIS_KERNEL_MODE
    "Build for Windows kernel-mode consumers"
    "${_zydis_kernel_mode_default}")
option(ZYAN_NO_LIBC "Build without C runtime library dependencies" "${ZYDIS_KERNEL_MODE}")

option(ZYDIS_MINIMAL_MODE
    "Enable minimal mode (forces ZYDIS_DECODER_MODE_MINIMAL runtime option)"
    OFF)
option(ZYDIS_FEATURE_DECODER "Enable instruction decoding functionality" ON)
option(ZYDIS_FEATURE_ENCODER "Enable instruction encoding functionality" ON)
option(ZYDIS_FEATURE_FORMATTER "Enable instruction formatting functionality" ON)
option(ZYDIS_FEATURE_AVX512 "Enable support for AVX-512 instructions" ON)
option(ZYDIS_FEATURE_KNC "Enable support for KNC instructions" ON)
option(ZYDIS_FEATURE_SEGMENT "Enable instruction segment API" ON)

set(_zydis_old_msvc_default OFF)
if(MSVC AND MSVC_VERSION LESS 1800)
    set(_zydis_old_msvc_default ON)
endif()
option(ZYDIS_COMPILE_AS_CXX_FOR_OLD_MSVC
    "Compile sources with the C++ frontend for old MSVC C compilers such as WDK 7"
    "${_zydis_old_msvc_default}")

set(_zydis_wdk7_compat_default OFF)
if(ZYDIS_KERNEL_MODE AND WDK7)
    set(_zydis_wdk7_compat_default ON)
endif()
option(ZYDIS_WDK7_COMPAT
    "Use the WDK 7 compatible no-libc minimal decoder profile"
    "${_zydis_wdk7_compat_default}")

if(ZYDIS_COMPILE_AS_CXX_FOR_OLD_MSVC)
    enable_language(CXX)
endif()

if(ZYDIS_WDK7_COMPAT)
    set(ZYAN_NO_LIBC ON CACHE BOOL "Build without C runtime library dependencies" FORCE)
    set(ZYDIS_MINIMAL_MODE ON CACHE BOOL
        "Enable minimal mode (forces ZYDIS_DECODER_MODE_MINIMAL runtime option)" FORCE)
    set(ZYDIS_FEATURE_ENCODER OFF CACHE BOOL "Enable instruction encoding functionality" FORCE)
    set(ZYDIS_FEATURE_FORMATTER OFF CACHE BOOL "Enable instruction formatting functionality" FORCE)
endif()

if(WDK7 AND ZYDIS_KERNEL_MODE AND NOT _zydis_wdk7_default_mode_is_kernel)
    foreach(_zydis_lang C CXX)
        set(CMAKE_${_zydis_lang}_FLAGS "")
        foreach(_zydis_config DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
            set(CMAKE_${_zydis_lang}_FLAGS_${_zydis_config} "")
        endforeach()
    endforeach()
endif()

if(ZYDIS_KERNEL_MODE AND NOT ZYAN_NO_LIBC)
    message(FATAL_ERROR "ZYDIS_KERNEL_MODE requires ZYAN_NO_LIBC")
endif()

if(ZYDIS_FEATURE_FORMATTER AND NOT ZYDIS_FEATURE_DECODER)
    message(FATAL_ERROR "ZYDIS_FEATURE_FORMATTER requires ZYDIS_FEATURE_DECODER")
endif()

if(ZYDIS_FEATURE_ENCODER AND
   (ZYDIS_MINIMAL_MODE OR NOT ZYDIS_FEATURE_DECODER OR
    NOT ZYDIS_FEATURE_AVX512 OR NOT ZYDIS_FEATURE_KNC))
    message(FATAL_ERROR
        "ZYDIS_FEATURE_ENCODER requires full decoder mode with AVX512 and KNC enabled")
endif()

function(_zydis_apply_common_settings target_name)
    target_include_directories("${target_name}"
        PUBLIC
            "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>")

    if(MSVC)
        target_compile_definitions("${target_name}" PRIVATE "_CRT_SECURE_NO_WARNINGS")
        target_compile_options("${target_name}" PRIVATE /W3)

        if(ZYAN_NO_LIBC AND NOT WDK7)
            target_compile_options("${target_name}" PRIVATE /GS- /Zl)
            set_property(TARGET "${target_name}" PROPERTY MSVC_RUNTIME_LIBRARY "")
        endif()
    endif()

    if(ZYAN_NO_LIBC)
        target_compile_definitions("${target_name}" PUBLIC "ZYAN_NO_LIBC")
    endif()

    if(ZYDIS_KERNEL_MODE)
        target_compile_definitions("${target_name}" PUBLIC "_KERNEL_MODE")

        if(WDK7 AND TARGET WDK7::Kernel AND NOT _zydis_wdk7_default_mode_is_kernel)
            get_target_property(_wdk7_kernel_include_dirs
                WDK7::Kernel INTERFACE_INCLUDE_DIRECTORIES)
            if(_wdk7_kernel_include_dirs)
                target_include_directories("${target_name}" PRIVATE ${_wdk7_kernel_include_dirs})
            endif()

            get_target_property(_wdk7_kernel_compile_options
                WDK7::Kernel INTERFACE_COMPILE_OPTIONS)
            if(_wdk7_kernel_compile_options)
                target_compile_options("${target_name}" PRIVATE ${_wdk7_kernel_compile_options})
            endif()
        endif()
    endif()
endfunction()

set(ZYCORE_HEADERS
    "include/Zycore/API/Memory.h"
    "include/Zycore/API/Process.h"
    "include/Zycore/API/Synchronization.h"
    "include/Zycore/API/Terminal.h"
    "include/Zycore/API/Thread.h"
    "include/Zycore/Allocator.h"
    "include/Zycore/ArgParse.h"
    "include/Zycore/Atomic.h"
    "include/Zycore/Bitset.h"
    "include/Zycore/Comparison.h"
    "include/Zycore/Defines.h"
    "include/Zycore/Format.h"
    "include/Zycore/Internal/AtomicGNU.h"
    "include/Zycore/Internal/AtomicMSVC.h"
    "include/Zycore/LibC.h"
    "include/Zycore/List.h"
    "include/Zycore/Object.h"
    "include/Zycore/Status.h"
    "include/Zycore/String.h"
    "include/Zycore/Types.h"
    "include/Zycore/Vector.h"
    "include/Zycore/Zycore.h")

set(ZYCORE_REQUIRED_SOURCES
    "src/Zycore/Allocator.c"
    "src/Zycore/Format.c"
    "src/Zycore/String.c"
    "src/Zycore/Vector.c"
    "src/Zycore/Zycore.c")

set(ZYCORE_EXTRA_SOURCES
    "src/Zycore/API/Memory.c"
    "src/Zycore/API/Process.c"
    "src/Zycore/API/Synchronization.c"
    "src/Zycore/API/Terminal.c"
    "src/Zycore/API/Thread.c"
    "src/Zycore/ArgParse.c"
    "src/Zycore/Bitset.c"
    "src/Zycore/List.c")

set(ZYCORE_SOURCES ${ZYCORE_REQUIRED_SOURCES})
if(NOT ZYAN_NO_LIBC)
    list(APPEND ZYCORE_SOURCES ${ZYCORE_EXTRA_SOURCES})
endif()

add_library(zycore ${ZYCORE_HEADERS} ${ZYCORE_SOURCES})
add_library(zydis::zycore ALIAS zycore)
add_library(Zycore::Zycore ALIAS zycore)

# Static (default): STATIC_BUILD makes the API macros expand to nothing, and it
# is PUBLIC so consumers see it too. Shared (BUILD_SHARED_LIBS=ON): SHOULD_EXPORT
# (PRIVATE) marks the API dllexport while this DLL is built; consumers without it
# get dllimport. Supports both `cmake ...` (static) and `-DBUILD_SHARED_LIBS=ON`.
if(BUILD_SHARED_LIBS)
    target_compile_definitions(zycore PRIVATE "ZYCORE_SHOULD_EXPORT")
else()
    target_compile_definitions(zycore PUBLIC "ZYCORE_STATIC_BUILD")
endif()
set_target_properties(zycore PROPERTIES
    OUTPUT_NAME "Zycore"
    POSITION_INDEPENDENT_CODE ON)
_zydis_apply_common_settings(zycore)

set(ZYDIS_BASE_HEADERS
    "include/Zydis/Defines.h"
    "include/Zydis/MetaInfo.h"
    "include/Zydis/Mnemonic.h"
    "include/Zydis/Register.h"
    "include/Zydis/SharedTypes.h"
    "include/Zydis/ShortString.h"
    "include/Zydis/Status.h"
    "include/Zydis/Utils.h"
    "include/Zydis/Zydis.h"
    "include/Zydis/Generated/EnumInstructionCategory.h"
    "include/Zydis/Generated/EnumISAExt.h"
    "include/Zydis/Generated/EnumISASet.h"
    "include/Zydis/Generated/EnumMnemonic.h"
    "include/Zydis/Generated/EnumRegister.h"
    "include/Zydis/Internal/SharedData.h"
    "include/Zydis/Internal/String.h")

set(ZYDIS_BASE_SOURCES
    "src/MetaInfo.c"
    "src/Mnemonic.c"
    "src/Register.c"
    "src/SharedData.c"
    "src/String.c"
    "src/Utils.c"
    "src/Zydis.c")

set(ZYDIS_GENERATED_TABLES
    "src/Generated/AccessedFlags.inc"
    "src/Generated/DecoderTables.inc"
    "src/Generated/EnumInstructionCategory.inc"
    "src/Generated/EnumISAExt.inc"
    "src/Generated/EnumISASet.inc"
    "src/Generated/EnumMnemonic.inc"
    "src/Generated/EnumRegister.inc"
    "src/Generated/FormatterStrings.inc"
    "src/Generated/GetRelInfo.inc"
    "src/Generated/InstructionDefinitions.inc"
    "src/Generated/InstructionEncodings.inc"
    "src/Generated/OperandDefinitions.inc"
    "src/Generated/RegisterClassLookup.inc"
    "src/Generated/RegisterLookup.inc"
    "src/Generated/EncoderTables.inc")

set(ZYDIS_DECODER_HEADERS
    "include/Zydis/Decoder.h"
    "include/Zydis/DecoderTypes.h"
    "include/Zydis/Internal/DecoderData.h")

set(ZYDIS_DECODER_SOURCES
    "src/Decoder.c"
    "src/DecoderData.c")

set(ZYDIS_ENCODER_HEADERS
    "include/Zydis/Encoder.h"
    "include/Zydis/Internal/EncoderData.h")

set(ZYDIS_ENCODER_SOURCES
    "src/Encoder.c"
    "src/EncoderData.c")

set(ZYDIS_FORMATTER_HEADERS
    "include/Zydis/Disassembler.h"
    "include/Zydis/Formatter.h"
    "include/Zydis/FormatterBuffer.h"
    "include/Zydis/Internal/FormatterATT.h"
    "include/Zydis/Internal/FormatterBase.h"
    "include/Zydis/Internal/FormatterIntel.h")

set(ZYDIS_FORMATTER_SOURCES
    "src/Disassembler.c"
    "src/Formatter.c"
    "src/FormatterATT.c"
    "src/FormatterBase.c"
    "src/FormatterBuffer.c"
    "src/FormatterIntel.c")

set(ZYDIS_SEGMENT_HEADERS
    "include/Zydis/Segment.h")

set(ZYDIS_SEGMENT_SOURCES
    "src/Segment.c")

set_source_files_properties(${ZYDIS_GENERATED_TABLES} PROPERTIES HEADER_FILE_ONLY TRUE)

if(ZYDIS_COMPILE_AS_CXX_FOR_OLD_MSVC)
    set_source_files_properties(
        ${ZYCORE_SOURCES}
        ${ZYDIS_BASE_SOURCES}
        ${ZYDIS_DECODER_SOURCES}
        ${ZYDIS_ENCODER_SOURCES}
        ${ZYDIS_FORMATTER_SOURCES}
        ${ZYDIS_SEGMENT_SOURCES}
        PROPERTIES LANGUAGE CXX)
endif()

add_library(zydis ${ZYDIS_BASE_HEADERS} ${ZYDIS_BASE_SOURCES} ${ZYDIS_GENERATED_TABLES})
add_library(zydis::zydis ALIAS zydis)
add_library(Zydis::Zydis ALIAS zydis)

target_link_libraries(zydis PUBLIC zycore)
target_include_directories(zydis PRIVATE "src")
if(BUILD_SHARED_LIBS)
    target_compile_definitions(zydis PRIVATE "ZYDIS_SHOULD_EXPORT")
else()
    target_compile_definitions(zydis PUBLIC "ZYDIS_STATIC_BUILD")
endif()
set_target_properties(zydis PROPERTIES
    OUTPUT_NAME "Zydis"
    VERSION "${PROJECT_VERSION}"
    POSITION_INDEPENDENT_CODE ON)
_zydis_apply_common_settings(zydis)

if(ZYDIS_FEATURE_DECODER)
    target_sources(zydis PRIVATE ${ZYDIS_DECODER_HEADERS} ${ZYDIS_DECODER_SOURCES})

    if(ZYDIS_FEATURE_ENCODER)
        target_sources(zydis PRIVATE ${ZYDIS_ENCODER_HEADERS} ${ZYDIS_ENCODER_SOURCES})
    endif()

    if(ZYDIS_FEATURE_FORMATTER AND NOT ZYDIS_MINIMAL_MODE)
        target_sources(zydis PRIVATE ${ZYDIS_FORMATTER_HEADERS} ${ZYDIS_FORMATTER_SOURCES})
    endif()

    if(ZYDIS_FEATURE_SEGMENT)
        target_sources(zydis PRIVATE ${ZYDIS_SEGMENT_HEADERS} ${ZYDIS_SEGMENT_SOURCES})
    endif()
endif()

if(ZYDIS_MINIMAL_MODE)
    target_compile_definitions(zydis PUBLIC "ZYDIS_MINIMAL_MODE")
endif()
if(NOT ZYDIS_FEATURE_DECODER)
    target_compile_definitions(zydis PUBLIC "ZYDIS_DISABLE_DECODER")
endif()
if(NOT ZYDIS_FEATURE_ENCODER)
    target_compile_definitions(zydis PUBLIC "ZYDIS_DISABLE_ENCODER")
endif()
if(NOT ZYDIS_FEATURE_FORMATTER)
    target_compile_definitions(zydis PUBLIC "ZYDIS_DISABLE_FORMATTER")
endif()
if(NOT ZYDIS_FEATURE_AVX512)
    target_compile_definitions(zydis PUBLIC "ZYDIS_DISABLE_AVX512")
endif()
if(NOT ZYDIS_FEATURE_KNC)
    target_compile_definitions(zydis PUBLIC "ZYDIS_DISABLE_KNC")
endif()
if(NOT ZYDIS_FEATURE_SEGMENT)
    target_compile_definitions(zydis PUBLIC "ZYDIS_DISABLE_SEGMENT")
endif()

source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}" FILES
    ${ZYCORE_HEADERS}
    ${ZYCORE_SOURCES}
    ${ZYDIS_BASE_HEADERS}
    ${ZYDIS_BASE_SOURCES}
    ${ZYDIS_GENERATED_TABLES}
    ${ZYDIS_DECODER_HEADERS}
    ${ZYDIS_DECODER_SOURCES}
    ${ZYDIS_ENCODER_HEADERS}
    ${ZYDIS_ENCODER_SOURCES}
    ${ZYDIS_FORMATTER_HEADERS}
    ${ZYDIS_FORMATTER_SOURCES}
    ${ZYDIS_SEGMENT_HEADERS}
    ${ZYDIS_SEGMENT_SOURCES})

# install()/find_package() support intentionally omitted: this fork is consumed
# only as a local CMake dependency (FetchContent / add_subdirectory), so the
# Zydis::Zydis and Zycore::Zycore targets are used directly. No export rules and
# no generated package config are produced.
