cmake_minimum_required(VERSION 3.14)

# ──────────────────────────────────────────────────────────────────────────────
project(tray VERSION 0.2 DESCRIPTION "A cross-platform C++ system-tray library"
               LANGUAGES CXX)

# ─── source files ─────────────────────────────────────────────────────────────
# Everything under tray/src/ (one recursive glob keeps it readable)
file(GLOB_RECURSE src CONFIGURE_DEPENDS "tray/src/*.cpp")
# macOS uses Objective-C++ (.mm files)
if(APPLE)
    file(GLOB_RECURSE src_mm CONFIGURE_DEPENDS "tray/src/*.mm")
    list(APPEND src ${src_mm})
endif()

add_library(tray STATIC ${src})

# ─── public headers ───────────────────────────────────────────────────────────
target_include_directories(tray
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tray/include>
        $<INSTALL_INTERFACE:include>)

# ─── platform-specific dependencies ───────────────────────────────────────────
if(UNIX AND NOT APPLE)
    find_package(PkgConfig REQUIRED)

    # Ask pkg-config to give us IMPORTED targets that already carry their flags
    pkg_check_modules(GTK3          REQUIRED IMPORTED_TARGET gtk+-3.0)
    pkg_check_modules(APPINDICATOR  REQUIRED IMPORTED_TARGET ayatana-appindicator3-0.1)
    pkg_check_modules(CAIRO         REQUIRED IMPORTED_TARGET cairo)

    # Link – using the IMPORTED targets automatically propagates include paths,
    # link libs (-lgtk-3, -lgdk-3, -lcairo, …) and extra compile flags (-pthread)
    target_link_libraries(tray
        PUBLIC                         # make the deps visible to consumers
            PkgConfig::GTK3
            PkgConfig::APPINDICATOR
            PkgConfig::CAIRO)

    # Extra warnings (but **no -Werror** on external code)
    if(CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|Clang)$")
        target_compile_options(tray PRIVATE -Wall -Wextra -pedantic)
    endif()

    # Only add -Wno-unused-lambda-capture if the compiler supports it
    include(CheckCXXCompilerFlag)
    check_cxx_compiler_flag("-Wno-unused-lambda-capture" HAS_WNO_UNUSED_LAMBDA)
    if(HAS_WNO_UNUSED_LAMBDA)
        target_compile_options(tray PRIVATE -Wno-unused-lambda-capture)
    endif()
elseif(APPLE)
    # macOS: Enable Objective-C++ for .mm files
    enable_language(OBJCXX)
    set_source_files_properties(${src_mm} PROPERTIES
        COMPILE_FLAGS "-x objective-c++")

    # Find and link Cocoa framework
    find_library(COCOA_LIBRARY Cocoa REQUIRED)
    target_link_libraries(tray PUBLIC ${COCOA_LIBRARY})

    # Extra warnings
    if(CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|Clang)$")
        target_compile_options(tray PRIVATE -Wall -Wextra -pedantic)
    endif()
endif()

# ─── language & misc properties ───────────────────────────────────────────────
target_compile_features(tray PRIVATE cxx_std_17)

set_target_properties(tray PROPERTIES
    CXX_STANDARD            17
    CXX_STANDARD_REQUIRED   YES
    CXX_EXTENSIONS          NO
    VERSION                 ${PROJECT_VERSION})

# (Optional) install rules – comment out if you don’t need “make install”
install(TARGETS tray
        EXPORT trayTargets
        ARCHIVE DESTINATION lib
        INCLUDES DESTINATION include)

install(DIRECTORY tray/include/ DESTINATION include)

export(EXPORT trayTargets
       FILE "${CMAKE_CURRENT_BINARY_DIR}/trayTargets.cmake")

