#!/usr/bin/env python

# Software automic installation

import sys
import getObject
from client import FtpClient
from client import HttpClient

__author__ = 'licy'


class Install(object):

    def __init__(self):
        print('\n*** Automic installation step just began now. ***')
        self.setting = getObject.Setting()
        self.checkin()
        # self.installation()
        print('** The automic installation step completed. ***\n')
        self.configuration()
        self.checkout()

    def checkin(self):
        pass

    def installation(self):
        pass

    def configuration(self):
        pass

    def checkout(self):
        pass


def main():
    sys.argv.append(
        '{"url": "http://192.168.170.2/iso/virtio-win-0.1-74.iso", "port": 80, "md5": "dd2b02a0dc301ec580c27256d21a269c"}')
    setting = Setting()
    if setting.port == 21:
        ftpclient = FtpClient()
        print('Use ftp protocol to download.')
        print('Starting download file %s ... ' % setting.file)
        ftpclient.getData(setting)
    else:
        httpclient = HttpClient()
        print('Use http protocol to download.')
        print('Starting download file %s ... ' % setting.file)
        httpclient.getData(setting)
        print('Download competed.')
    # Check folder if exists.


if __name__ == '__main__':
    main()
