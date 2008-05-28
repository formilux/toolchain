#!/bin/bash
while read; do
    if [ -e ${PKGROOT:-/var/flx-pkg}/$REPLY ]; then
        echo ${PKGROOT:-/var/flx-pkg}/$REPLY
    elif [ -e ${PKGROOT:-/var/flx-pkg}/${REPLY}-flx* ]; then
        echo ${PKGROOT:-/var/flx-pkg}/${REPLY}-flx*
    else
        echo $REPLY
    fi
done
