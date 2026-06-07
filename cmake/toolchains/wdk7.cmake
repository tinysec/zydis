set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_USER_MAKE_RULES_OVERRIDE
    "${CMAKE_CURRENT_LIST_DIR}/wdk7-rules.cmake")

if(NOT DEFINED WDK7_ROOT OR WDK7_ROOT STREQUAL "")
    if(DEFINED ENV{BASEDIR} AND NOT "$ENV{BASEDIR}" STREQUAL "")
        file(TO_CMAKE_PATH "$ENV{BASEDIR}" WDK7_ROOT)
    else()
        set(WDK7_ROOT "C:/WinDDK/7600.16385.1")
    endif()
endif()

if(NOT EXISTS "${WDK7_ROOT}/bin/setenv.bat")
    message(WARNING
        "WDK7_ROOT does not point to a WDK 7 installation. "
        "Call setenv.bat before configuring or pass -DWDK7_ROOT=<path>.")
endif()

set(CMAKE_C_COMPILER cl CACHE FILEPATH "WDK 7 C compiler")
set(CMAKE_CXX_COMPILER cl CACHE FILEPATH "WDK 7 C++ compiler")
set(CMAKE_C_FLAGS_INIT "/nologo")
set(CMAKE_CXX_FLAGS_INIT "/nologo")

find_program(_WDK7_LINKER link PATHS ENV PATH NO_DEFAULT_PATH)
if(_WDK7_LINKER)
    set(CMAKE_LINKER "${_WDK7_LINKER}" CACHE FILEPATH "WDK 7 linker")
    set(CMAKE_AR "${_WDK7_LINKER}" CACHE FILEPATH "WDK 7 librarian")
    set(CMAKE_RANLIB "" CACHE FILEPATH "WDK 7 ranlib")
endif()
