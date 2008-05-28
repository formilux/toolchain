while read ; do if [ -e /var/flx-pkg/$REPLY ]; then echo /var/flx-pkg/$REPLY; elif [ -e /var/flx-pkg/${REPLY}-flx* ]; then echo /var/flx-pkg/${REPLY}-flx*; else echo $REPLY;fi; done
