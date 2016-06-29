#!/usr/bin/env python
# -*- encoding:utf-8 -*-
# Software automic installation

import os
import sys
import json
import logging

__author__ = 'licy'

BASE_DIR = os.path.split(os.path.abspath(__file__))[0]
CONFIG_DIR = os.path.join(BASE_DIR, 'config')
TEMP_DIR = os.path.join(BASE_DIR, 'temp')
LOG_DIR = os.path.join(BASE_DIR, 'log')


class SetInstallLog:
    def __init__(self, logname):
        self.logname = logname
        self.logger = logging
        if not os.path.exists(LOG_DIR):
            os.mkdir(LOG_DIR)
        self.logger.basicConfig(level=logging.DEBUG,
                                format='%(asctime)s %(filename)s[line:%(lineno)d]' +
                                '%(levelname)s %(message)s',
                                datefmt='%a, %d %b %Y %H:%M:%S',
                                filename=os.path.join(
                                    LOG_DIR, self.logname),
                                filemode='a'
                                )
        self.console = self.logger.StreamHandler()
        self.console.setLevel(self.logger.INFO)
        self.formatter = self.logger.Formatter(
            '%(name)-4s %(levelname)-4s %(message)s')
        self.console.setFormatter(self.formatter)
        self.logger.getLogger('').addHandler(self.console)

    def debug(self, msg):
        self.logger.debug(msg)

    def info(self, msg):
        self.logger.info(msg)

    def warning(self, msg):
        self.logger.warning(msg)


class Setting(object):

    def __init__(self, string):
        self.__dict__ = dict(json.loads(string))
        self.url = self.__dict__.get('url')
        self.port = self.__dict__.get('port', 21)
        self.user = self.__dict__.get('user', 'anonymous')
        self.pawd = self.__dict__.get('pawd', '')
        self.md5 = self.__dict__.get('md5', '')
        self.url_parse()
        self.directory()
        self.local = os.path.join(self.storage, self.file)
        self.root = BASE_DIR
        self.buff = 1024

    def url_parse(self):
        import re
        ip_parttern = re.compile(r'(\d+)\.(\d+)\.(\d+)\.(\d+)')
        search = ip_parttern.search(self.url)
        self.host = search.group()
        filename = self.url.split(self.host)[-1]
        self.path, self.file = os.path.split(filename)
        if self.path[0] == '/':
            self.path = self.path[1:]

    def directory(self):
        self.storage = os.path.join(BASE_DIR, 'data')
        if not os.path.exists(self.storage):
            os.mkdir(self.storage)

        self.temp = os.path.join(BASE_DIR, 'temp')
        if not os.path.exists(self.temp):
            os.mkdir(self.temp)

        self.log = os.path.join(BASE_DIR, 'log')
        if not os.path.exists(self.log):
            os.mkdir(self.log)

        self.conf = os.path.join(BASE_DIR, 'conf')
        if not os.path.exists(self.conf):
            os.mkdir(self.conf)


def main():
    setting = Setting()
    print(setting.file)
    print(setting.log)
    # Check folder if exists.


if __name__ == '__main__':
    main()
