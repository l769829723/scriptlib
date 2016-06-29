#!/usr/bin/env python
# -*- encoding:utf-8 -*-
# Software automic installation

import os
import socket
import ftplib
import hashlib

try:
    import urllib.request as urllib2
except ImportError:
    import urllib2

__author__ = 'licy'


def submd5(filename):
    if not os.path.isfile(filename):
        return False
    myhash = hashlib.md5()
    with open(filename, 'rb') as file:
        myhash.update(file.read())
    return myhash.hexdigest()


def md5check(source, dest):
    if source != '':
        if source == dest:
            return True
        else:
            return False

def autodownload(string):
    '''   '''

class FtpClient(object):
    def getData(self, setting):
        self.setting = setting
        try:
            ftp = ftplib.FTP()
            ftp.connect(self.setting.host, self.setting.port, timeout=30)
            ftp.login(self.setting.user, self.setting.pawd)
            ftp.cwd(self.setting.path)
            filename = 'RETR ' + self.setting.file
            with open(self.setting.local, 'wb') as local:
                ftp.retrbinary(filename, local.write)
            ftp.quit()
        except (socket.error, socket.gaierror):
            print('Can not connect to self.setting %s .' % self.setting.host)
        except ftplib.error_perm:
            print('Can not login, user: %s password: %s, please retry.' %
                  (self.setting.user, self.setting.pawd))
            print('Maybe can not use the path: %s .' % self.setting.path)
            print('Maybe network by closed.')
        else:
            print('The file %s Download competed.' % self.setting.file)
            print('Saved in dir %s .' % self.setting.storage)

    def checkmd5(self):
        return md5check(self.setting.md5, submd5(self.setting.local))


class HttpClient(object):

    def getData(self, setting):
        self.setting = setting
        http = urllib2.urlopen(self.setting.url)
        with open(self.setting.local, 'wb') as file:
            while True:
                buff = http.read(self.setting.buff)
                if len(buff) == 0:
                    break
                file.write(buff)
        http.close()

    def checkmd5(self):
        return md5check(self.setting.md5, submd5(self.setting.local))
