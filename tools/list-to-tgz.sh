#!/bin/bash
while read ; do
  if [ -e /var/flx-pkg/$REPLY ]; then
    d=/var/flx-pkg/$REPLY
  elif [ -e /var/flx-pkg/${REPLY}-flx0* ]; then
    d=/var/flx-pkg/${REPLY}-flx0*
  else
    echo "$REPLY not resolved!"
  fi
  p=${d##*/}; f=""

  for a in "" "-noarch" "-i586" "-i486" "-i386"; do
    if [ -e $d/compiled/${p}${a}.tgz ]; then
      f=$(echo $d/compiled/${p}${a}.tgz)
      break
    fi
  done

  if [ -z "$f" ]; then
    echo "No file found for package $p"
  fi
  echo "$f"
done
