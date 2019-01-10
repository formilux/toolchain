#!/bin/bash

set -e
if ! [ -f ./maintainer/git-version-gen ] || ! [ -d .git ]; then
    echo "You must be inside a ct-ng cloned with git!"
    exit 1
fi
CT_PKG_NAME=crosstool-ng-`./maintainer/git-version-gen --prefix crosstool-ng- .tarball-version`
mydir="`basename "$(pwd)"`"
cd ..
rm -fr "$CT_PKG_NAME"
echo "Copying the sources..."
cp -a "$mydir" "$CT_PKG_NAME"
echo "Compressing the sources..."
tar cf - "$CT_PKG_NAME" | bzip2 > "${CT_PKG_NAME}.tar.bz2"
echo "Deleting the uncompressed directory..."
rm -fr "$CT_PKG_NAME"
echo "`realpath "${CT_PKG_NAME}.tar.bz2"` is ready, you have to copy it into the sources dir."
cd - > /dev/null
exit 0
