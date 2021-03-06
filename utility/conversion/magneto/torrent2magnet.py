#!/usr/bin/python
#Description: converts a torrent file to a magnet link
#Source: https://github.com/danfolkes/Magnet2Torrent/issues/6
import libtorrent
import sys

session = libtorrent.session()
info = libtorrent.torrent_info(sys.argv[1])
print "magnet:?xt=urn:btih:%s&dn=%s" % (info.info_hash(), info.name())
exit
