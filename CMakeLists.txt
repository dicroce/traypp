if(UNIX)
    find_package(PkgConfig REQUIRED)

    pkg_check_modules(GTK3          REQUIRED gtk+-3.0)
    pkg_check_modules(APPINDICATOR  REQUIRED ayatana-appindicator3-0.1)

    # Headers → propagate to users of tray
    target_include_directories(tray
        PUBLIC
            ${GTK3_INCLUDE_DIRS}
            ${APPINDICATOR_INCLUDE_DIRS}
            ${PROJECT_SOURCE_DIR}/tray/include      # your own headers
        SYSTEM PUBLIC                               # mark as system to silence warnings
            ${GTK3_INCLUDE_DIRS} ${APPINDICATOR_INCLUDE_DIRS}
    )

    # Link flags → propagate to users of tray
    target_link_libraries(tray
        PUBLIC            # <── this is the key change
            ${GTK3_LIBRARIES}
            ${APPINDICATOR_LIBRARIES}
    )

    # CFLAGS from pkg-config (e.g. -pthread, -D_REENTRANT)
    target_compile_options(tray
        PUBLIC ${GTK3_CFLAGS_OTHER} ${APPINDICATOR_CFLAGS_OTHER}
        PRIVATE -Wall -Wextra -Werror -pedantic -Wno-unused-lambda-capture
    )
endif()

target_include_directories(tray PUBLIC tray/include)
target_compile_features(tray PRIVATE cxx_std_17)
