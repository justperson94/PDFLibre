#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/usr/lib/pdflibre/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/lib/pdflibre/pdflibre" "$@"
