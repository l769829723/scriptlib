#!/usr/bin/env python
# -*- encoding:utf-8 -*-
# Software automic installation

import tarfile
import os
import sys
import subprocess
import traceback

from getObject import Setting
from client import FtpClient
from client import HttpClient
from getObject import SetInstallLog


class Db2install:

    def __init__(self):
        print('\n*** Automic installation step just began now. ***\n')
        arguments = ''
        if len(sys.argv) > 1:
            arguments = sys.argv[1]
        else:
            arguments = '{"url": "http://192.168.170.2/isoshare/v10.5_linuxx64_server_t.tar.gz", "port": 80}'
        self.logger = SetInstallLog('install.log')
        self.logger.debug(arguments)
        self.setting = Setting(arguments)
        self.checkin()

    def checkin(self):
        if not os.path.isfile(os.path.join(self.setting.conf, 'db2server.rsp')):
            self.logger.warning('Error: Configuration file not found.')
            sys.exit(1)
        else:
            self.logger.info('Configuration file found.')

        if not os.path.isfile(os.path.join(self.setting.storage, self.setting.file)):
            self.logger.info(
                'Installation package file not found, will be download.')
            if self.setting.port == 21:
                ftpclient = FtpClient()
                self.logger.info('Downloading file %s ...' %
                                 self.setting.file)
                ftpclient.getData(self.setting)
            else:
                httpclient = HttpClient()
                self.logger.info('Starting download file %s ...' %
                                 self.setting.file)
                httpclient.getData(self.setting)
        else:
            self.logger.info('Installation package file found in %s .' %
                             self.setting.storage)

        self.installation()

    def installation(self):
        self.logger.info('Unpacking the package file ... ')
        tar = tarfile.open(os.path.join(
            self.setting.storage, self.setting.file))
        tar.extractall(self.setting.temp)
        self.logger.info('Package file unpack done.')
        self.logger.info('Get ready for installation, will take a time.')
        p = subprocess.Popen(
            [os.path.join(self.setting.temp, 'server_t', 'db2setup'),
             '-r', os.path.join(self.setting.conf, 'db2server.rsp')],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, shell=False)
        stdout, stderr = p.communicate()
        if p.poll() == 0:
            self.checkout()
            self.logger.info(
                '*** The automic installation step completed. ***\n')
        else:
            self.logger.warning(
                'Error: The automic installation step fault.\n')
            exit(2)
        self.logger.warning(stderr)
        self.logger.warning(stdout)

    def checkout(self):
        print('Cleanning installation data ...')
        p = subprocess.Popen(['rm', '-rf', self.setting.root],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             shell=False)
        p.wait()
        if p.poll() == 0:
            self.logger.info('Cleanning done.')
            exit(0)
        else:
            self.logger.warning('Cleanning fault.')


def main():
    logger = SetInstallLog('install_debug.log')
    try:
        Db2install()
    except:
        logger.debug(traceback.format_exc())


if __name__ == '__main__':
    main()
