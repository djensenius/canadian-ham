#!/bin/bash
# Both compilation and resource copying use OFFICIAL_REFERENCE_SHEET. Always remove
# stale resources so reusing a build directory cannot leak an earlier opt-in.
set -euo pipefail
destination="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/official-basic-exam"
rm -rf "${destination}"
case " ${SWIFT_ACTIVE_COMPILATION_CONDITIONS:-} ${OTHER_SWIFT_FLAGS:-} " in
  *" OFFICIAL_REFERENCE_SHEET "*|*" -DOFFICIAL_REFERENCE_SHEET "*)
    mkdir -p "${destination}"
    cp "${SRCROOT}/../../content/reference/official-basic-exam/"{page-*.png,text-equivalent.md} "${destination}/"
    ;;
esac
