cmake_minimum_required(VERSION 3.20)

project(zydis_wdk7_smoke LANGUAGES C)

if(NOT WDK7)
    message(FATAL_ERROR "Configure this test with the WDK7 toolchain")
endif()

string(TOUPPER "${WDK7_DEFAULT_MODE}" _wdk7_default_mode)
if(NOT _wdk7_default_mode STREQUAL "KERNEL")
    message(FATAL_ERROR "Configure this test with -DWDK7_DEFAULT_MODE=KERNEL")
endif()

find_package(zydis 4.1.1 CONFIG REQUIRED)

add_library(zydis_wdk7_smoke_driver SHARED smoke_driver.c)
target_link_libraries(zydis_wdk7_smoke_driver
    PRIVATE
        zydis::zydis
        WDK7::KernelWdm)
target_link_options(zydis_wdk7_smoke_driver
    PRIVATE
        /DRIVER
        /SUBSYSTEM:NATIVE)

if(WDK7_ARCH STREQUAL "i386")
    target_link_options(zydis_wdk7_smoke_driver PRIVATE /ENTRY:DriverEntry@8)
else()
    target_link_options(zydis_wdk7_smoke_driver PRIVATE /ENTRY:DriverEntry)
endif()

set_target_properties(zydis_wdk7_smoke_driver PROPERTIES
    PREFIX ""
    OUTPUT_NAME "zydis_wdk7_smoke"
    SUFFIX ".sys")
