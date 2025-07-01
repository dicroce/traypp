cmake_minimum_required(VERSION 3.14)
project(tray VERSION 0.2 LANGUAGES CXX)

# ① Gather sources – use CONFIGURE_DEPENDS so the list regenerates after git pull
file(GLOB src CONFIGURE_DEPENDS
     "src/*.cpp"          # <- drop the extra “tray/” prefix; we are already in that dir
     "src/*/*.cpp"
     "src/*/*/*.cpp")

# ② Create the target *before* you start adding properties to it
add_library(tray STATIC ${src})

# ③ Common include path (visible everywhere)
target_include_directories(tray
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>)          # for “make install”

# ④ Linux-only extras
if(UNIX AND NOT APPLE)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GTK3          REQUIRED gtk+-3.0)
    pkg_check_modules(APPINDICATOR  REQUIRED ayatana-appindicator3-0.1)

    # Propagate compile flags that pkg-config emits (-pthread, -D_REENTRANT, …)
    target_compile_options(tray PUBLIC
        ${GTK3_CFLAGS_OTHER}
        ${APPINDICATOR_CFLAGS_OTHER}
        -Wall -Wextra -Werror -pedantic
        -Wno-unused-lambda-capture)

    # Make the GTK / AppIndicator libs flow through to anything that links tray
    target_link_libraries(tray PUBLIC
        ${GTK3_LIBRARIES}
        ${APPINDICATOR_LIBRARIES})
endif()

# ⑤ C++ standard & misc properties
target_compile_features(tray PRIVATE cxx_std_17)
set_target_properties(tray PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED YES
    CXX_EXTENSIONS     NO
    VERSION            ${PROJECT_VERSION})


