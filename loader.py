#!/usr/bin/env python3
#   JSON Database Loader script
#   Copyright (C) 2020  The Genesis Project
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.

import json
import os
import shutil
import sys
from datetime import date
from glob import glob
from os import system as bash

# Colors makes things beautiful
black = "\033[30m"
red = "\033[31m"
green = "\033[32m"
yellow = "\033[33m"
blue = "\033[34m"
purple = "\033[35m"
cyan = "\033[36m"
white = "\033[37m"
reset = "\033[m"

# Directory variable
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
HOME_DIR = os.path.dirname(SCRIPT_DIR)
VAR_DIR = f'{HOME_DIR}/var'
ROMREPO_DIR = f'{HOME_DIR}/rom'


def check_parameters(parameters):
    for parameter in parameters:
        if parameter is None:
            print(red+"Missing parameters!"+reset)
            sys.exit(1)


def get_device_variable(device_codename):
    database_file = f'{SCRIPT_DIR}/device.database'
    database = glob(database_file)
    if database:
        print(yellow+"Loading Device info from database."+reset)
        with open(database[0]) as db:
            devices = json.load(db)
    else:
        devices = {}
        print(red+"Device database file not found."+reset)
        sys.exit(1)

    device = devices[f'{device_codename}']
    return device


def get_rom_variable(android_version, rom_name):
    database_file = f'{SCRIPT_DIR}/rom.database'
    database = glob(database_file)
    if database:
        print(yellow+"Loading ROM parameters from database."+reset)
        with open(database[0]) as db:
            parameters = json.load(db)
    else:
        parameters = {}
        print(red+"ROM database file not found."+reset)
        sys.exit(1)

    rom = parameters[f'{android_version}'][f'{rom_name}']
    return rom


def main():
    device_codename = os.getenv('DEVICE_CODENAME')
    android_version = os.getenv('ANDROID_VERSION')
    rom_name = os.getenv('ROM')
    dt_repo = os.getenv('DT_REPO')
    dt_branch = os.getenv('DT_BRANCH')
    build_type = os.getenv('BUILD_TYPE')
    gapps_option = os.getenv('GAPPS_OPTION')
    clean_ccache = os.getenv('CLEAN_CCACHE')
    clean_build = os.getenv('CLEAN_BUILD')
    upload_method = os.getenv('UPLOAD_METHOD')
    parameters = [
        device_codename,
        android_version,
        rom_name,
        dt_repo,
        dt_branch,
        build_type,
        gapps_option,
        clean_ccache,
        clean_build,
        upload_method
    ]
    check_parameters(parameters)

    device = get_device_variable(device_codename)
    device_name = device[0]
    device_codename = device[1]
    device_manufacturer = device[2]
    for i in range(0,3):
        with open(f'{VAR_DIR}/device.{i}', 'wt') as vf:
            vf.write(device[i])
            vf.close()

    rom = get_rom_variable(android_version, rom_name)
    rom_name = rom[0]
    target_command = rom[1]
    lunch_command = rom[2]
    rom_repo = rom[3]
    rom_branch = rom[4]
    rom_drive = rom[5]
    for i in range(0,6):
        with open(f'{VAR_DIR}/rom.{i}', 'wt') as vf:
            vf.write(rom[i])
            vf.close()

    with open(f'{VAR_DIR}/android', 'wt') as vf:
        vf.write(android_version)
        vf.close()

    print(blue+f"Device  : {device_codename}"+reset)
    print(blue+f"ROM     : {rom_name}"+reset)
    print(blue+f"Android : {android_version}"+reset)
    print(blue+f"GApps   : {gapps_option}"+reset)

if __name__ == "__main__":
    main()
