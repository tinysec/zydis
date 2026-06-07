cmake_minimum_required(VERSION 3.20)

if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.15")
    cmake_policy(SET CMP0091 NEW)
endif()

if(NOT DEFINED ZYDIS_VERSION OR ZYDIS_VERSION STREQUAL "")
    set(ZYDIS_VERSION "4.1.1")
endif()

project(zydis VERSION "${ZYDIS_VERSION}" LANGUAGES C)

if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set(_zydis_is_top_level TRUE)
else()
    set(_zydis_is_top_level FALSE)
endif()

include(GNUInstallDirs)

option(ZYDIS_INSTALL "Install the zydis CMake package" "${_zydis_is_top_level}")

option(ZYDIS_KERNEL_MODE "Build for Windows kernel-mode consumers" OFF)
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
if(ZYDIS_KERNEL_MODE AND _zydis_old_msvc_default)
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
            "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
            "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>")

    if(MSVC)
        target_compile_definitions("${target_name}" PRIVATE "_CRT_SECURE_NO_WARNINGS")
        target_compile_options("${target_name}" PRIVATE /W3)

        if(ZYAN_NO_LIBC)
            target_compile_options("${target_name}" PRIVATE /GS- /Zl)
            set_property(TARGET "${target_name}" PROPERTY MSVC_RUNTIME_LIBRARY "")
        endif()
    endif()

    if(ZYAN_NO_LIBC)
        target_compile_definitions("${target_name}" PUBLIC "ZYAN_NO_LIBC")
    endif()

    if(ZYDIS_KERNEL_MODE)
        target_compile_definitions("${target_name}" PUBLIC "_KERNEL_MODE")
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

add_library(zycore STATIC ${ZYCORE_HEADERS} ${ZYCORE_SOURCES})
add_library(zydis::zycore ALIAS zycore)
add_library(Zycore::Zycore ALIAS zycore)

target_compile_definitions(zycore PUBLIC "ZYCORE_STATIC_BUILD")
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

add_library(zydis STATIC ${ZYDIS_BASE_HEADERS} ${ZYDIS_BASE_SOURCES} ${ZYDIS_GENERATED_TABLES})
add_library(zydis::zydis ALIAS zydis)
add_library(Zydis::Zydis ALIAS zydis)

target_link_libraries(zydis PUBLIC zycore)
target_include_directories(zydis PRIVATE "src")
target_compile_definitions(zydis PUBLIC "ZYDIS_STATIC_BUILD")
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

if(ZYDIS_INSTALL)
    install(
        TARGETS zycore zydis
        EXPORT zydisTargets
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
        INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

    install(
        DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include/"
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

    install(
        FILES "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE"
        DESTINATION "${CMAKE_INSTALL_DOCDIR}")

    install(
        FILES "${CMAKE_CURRENT_SOURCE_DIR}/THIRD_PARTY_LICENSES/Zycore-LICENSE"
        DESTINATION "${CMAKE_INSTALL_DOCDIR}/third-party")

    install(
        EXPORT zydisTargets
        FILE zydisTargets.cmake
        NAMESPACE zydis::
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/zydis")

    include(CMakePackageConfigHelpers)

    write_basic_package_version_file(
        "${PROJECT_BINARY_DIR}/zydisConfigVersion.cmake"
        VERSION "${PROJECT_VERSION}"
        COMPATIBILITY SameMajorVersion)

    configure_package_config_file(
        "${PROJECT_SOURCE_DIR}/cmake/Config.cmake.in"
        "${PROJECT_BINARY_DIR}/zydisConfig.cmake"
        INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/zydis")

    install(
        FILES
            "${PROJECT_BINARY_DIR}/zydisConfig.cmake"
            "${PROJECT_BINARY_DIR}/zydisConfigVersion.cmake"
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/zydis")
endif()
