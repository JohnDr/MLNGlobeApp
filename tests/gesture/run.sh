#!/bin/bash
# Runs the gesture-logic tests (reads ../../main.qml). Headless: offscreen platform.
cd "$(dirname "$0")"
export QML_XHR_ALLOW_FILE_READ=1 QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-offscreen}
exec "${QMLTESTRUNNER:-$HOME/Qt/6.11.2/gcc_64/bin/qmltestrunner}" -input tst_gesture.qml "$@"
