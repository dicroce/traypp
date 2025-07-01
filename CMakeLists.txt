cmake_minimum_required(VERSION 3.14)
project(tray VERSION 0.2 LANGUAGES CXX)

# --- source files -----------------------------------------------------------
file(GLOB_RECURSE src CONFIGURE_DEPENDS
     "tray/src/*.cpp")            # ← matches tray/src/* and deeper

add_library(tray STATIC ${src})

# --- public headers ---------------------------------------------------------
target_include_directories(tray
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tray/include>
        $<INSTALL_INTERFACE:include>)

# --- Linux-only (GTK/AppIndicator) bits -------------------------------------
if(UNIX AND NOT APPLE)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GTK3          REQUIRED gtk+-3.0)
    pkg_check_modules(APPINDICATOR  REQUIRED ayatana-appindicator3-0.1)
    
    target_include_directories(tray
    PUBLIC
        ${GTK3_INCLUDE_DIRS}
        ${APPINDICATOR_INCLUDE_DIRS})

    target_compile_options(tray PUBLIC
        ${GTK3_CFLAGS_OTHER}
        ${APPINDICATOR_CFLAGS_OTHER}
        -Wall -Wextra -Werror -pedantic -Wno-unused-lambda-capture)

    target_link_libraries(tray PUBLIC
        ${GTK3_LIBRARIES}
        ${APPINDICATOR_LIBRARIES})
endif()

# --- misc properties --------------------------------------------------------
target_compile_features(tray PRIVATE cxx_std_17)
set_target_properties(tray PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED YES
    CXX_EXTENSIONS     NO
    VERSION            ${PROJECT_VERSION})

