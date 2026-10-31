# HunterbornNative.dll on alandtse's CommonLibSSE-NG; included by E:/WorkSpace/ng-build/CMakeLists.txt (see ng_plugin there)
ng_plugin(TARGET HunterbornNative NAME HunterbornNative VERSION 0.1.0 ROOT "${CMAKE_CURRENT_LIST_DIR}"
    SOURCES src/main.cpp src/Settings.cpp src/Actions.cpp src/AutoPatch.cpp src/Menu.cpp src/Hotkeys.cpp src/Notifications.cpp src/Animallica.cpp src/HunterbornIds.cpp
    INCLUDES "${CMAKE_CURRENT_LIST_DIR}/src" "${CMAKE_CURRENT_LIST_DIR}/include"
    PCH "${CMAKE_CURRENT_LIST_DIR}/src/PCH.h")
