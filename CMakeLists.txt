cmake_minimum_required(VERSION 3.19...3.21)

project(MLNGlobeApp VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 REQUIRED)
qt_standard_project_setup()

if(QT_KNOWN_POLICY_QTP0002)
    qt_policy(SET QTP0002 NEW)
endif()

find_package(QMapLibre COMPONENTS Core Quick REQUIRED)

qt_add_executable(
    MLNGlobeApp
    main.cpp
)

qt_add_qml_module(
    MLNGlobeApp
    URI MLNGlobeApp
    VERSION 1.0
    RESOURCE_PREFIX "/"
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/qml/MLNGlobeApp"
    QML_FILES
        main.qml
)

# Terrain styles, embedded so they are available on every platform (Android
# cannot read the developer-machine paths used for the desktop file:// URLs).
qt_add_resources(MLNGlobeApp map_styles
    PREFIX "/"
    FILES
        terrain-style.json
        gljs-terrain-style.json
)

set_target_properties(
    MLNGlobeApp
    PROPERTIES
        WIN32_EXECUTABLE ON
        MACOSX_BUNDLE ON
        QT_WASM_PTHREAD_POOL_SIZE 16
)

target_link_libraries(
    MLNGlobeApp
    PRIVATE
        Qt::Quick
        Qt::QuickControls2
        QMapLibre::Core
)

# Copy the QMapLibre runtime next to the executable so the app (and the
# MapLibre QML plugin, which depends on QMapLibre's private libraries) can be
# run directly, e.g. from Qt Creator, without QMapLibre's bin directory on PATH.
if(WIN32)
    get_filename_component(_QMapLibre_prefix "${QMapLibre_DIR}/../../.." ABSOLUTE)
    file(GLOB _QMapLibre_runtime_dlls "${_QMapLibre_prefix}/bin/*.dll")
    if(_QMapLibre_runtime_dlls)
        add_custom_command(
            TARGET MLNGlobeApp POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    ${_QMapLibre_runtime_dlls} "$<TARGET_FILE_DIR:MLNGlobeApp>/"
            COMMENT "Copying QMapLibre runtime next to the executable"
        )
    endif()
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
    target_link_options(
        MLNGlobeApp
        PRIVATE
            -sTEXTDECODER=0
    )
endif()

qmaplibre_quick_setup_plugins(MLNGlobeApp)

install(
    TARGETS MLNGlobeApp
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET MLNGlobeApp
    OUTPUT_SCRIPT deploy_script
    MACOS_BUNDLE_POST_BUILD
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
)
install(SCRIPT ${deploy_script})

if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    install(
        IMPORTED_RUNTIME_ARTIFACTS QMapLibre::Core
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Android")
    include(FetchContent)
    FetchContent_Declare(
        android_openssl
        DOWNLOAD_EXTRACT_TIMESTAMP true
        URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)

    add_android_openssl_libraries(MLNGlobeApp)

    # Bundle Qt's WebP imageformats plugin, which the Qt CI deployment omits by
    # default. Without it QImage/QImageReader cannot decode WebP, so WebP raster
    # tiles fail (e.g. the Open Waters elevation/terrain source).
    if(DEFINED ENV{QT_ROOT_DIR})
        file(TO_CMAKE_PATH "$ENV{QT_ROOT_DIR}" _qmaplibre_qt_root)
        set(_qmaplibre_webp_plugin
            "${_qmaplibre_qt_root}/plugins/imageformats/libplugins_imageformats_qwebp_${ANDROID_ABI}.so")
        if(EXISTS "${_qmaplibre_webp_plugin}")
            set_property(TARGET MLNGlobeApp APPEND PROPERTY
                QT_ANDROID_EXTRA_LIBS "${_qmaplibre_webp_plugin}")
        endif()
    endif()
endif()

# Packaging
set(CPACK_GENERATOR TBZ2)
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(CPACK_SYSTEM_NAME "macOS")
else()
    set(CPACK_SYSTEM_NAME "${CMAKE_SYSTEM_NAME}")
endif()

include(CPack)
