#!/usr/bin/env python3
#   Unified Roomservice script
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
import sys
from glob import glob
from xml.etree import ElementTree

DEBUG = False

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
HOME_DIR = os.path.dirname(SCRIPT_DIR)
ROMREPO_DIR = f'{HOME_DIR}/rom'

custom_default_revision = os.getenv('ROOMSERVICE_DEFAULT_BRANCH')
custom_local_manifest = '.repo/local_manifests/device.xml'
custom_dependencies = "*.dependencies"
local_manifests = '.repo/local_manifests'
if not os.path.exists(local_manifests):
    os.makedirs(local_manifests)


def debug(*args, **kwargs):
    if DEBUG:
        print(*args, **kwargs)


def indent(elem, level=0):
    # in-place prettyprint formatter
    i = "\n" + "  " * level
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i


def get_manifest_path():
    '''Find the current manifest path
    In old versions of repo this is at .repo/manifest.xml
    In new versions, .repo/manifest.xml includes an include
    to some arbitrary file in .repo/manifests'''

    m = ElementTree.parse('.repo/manifest.xml')
    try:
        m.findall('default')[0]
        return '.repo/manifest.xml'
    except IndexError:
        return '.repo/manifests/{}'.format(m.find("include").get("name"))


def load_manifest(manifest):
    try:
        man = ElementTree.parse(manifest).getroot()
    except (IOError, ElementTree.ParseError):
        man = ElementTree.Element("manifest")
    return man


def get_default(manifest=None):
    m = manifest or load_manifest(get_manifest_path())
    d = m.findall('default')[0]
    return d


def get_remote(manifest=None, remote_name=None):
    m = manifest or load_manifest(get_manifest_path())
    if not remote_name:
        remote_name = get_default(manifest=m).get('remote')
    remotes = m.findall('remote')
    for remote in remotes:
        if remote_name == remote.get('name'):
            return remote


def get_from_manifest(device_name):
    if os.path.exists(custom_local_manifest):
        man = load_manifest(custom_local_manifest)
        for local_path in man.findall("project"):
            lp = local_path.get("path").strip('/')
            if lp.startswith("device/") and lp.endswith("/" + device_name):
                return lp
    return None


def is_in_manifest(project_path):
    for man in (custom_local_manifest, get_manifest_path()):
        man = load_manifest(man)
        for local_path in man.findall("project"):
            if local_path.get("path") == project_path:
                return True
    return False


def add_to_manifest(repos, fallback_branch=None):
    lm = load_manifest(custom_local_manifest)

    for repo in repos:
        repo_name = repo['repository']
        repo_path = repo['target_path']
        if 'branch' in repo:
            repo_branch = repo['branch']
        else:
            repo_branch = custom_default_revision
        if 'remote' in repo:
            repo_remote = repo['remote']
        elif "/" in repo_name:
            repo_remote = "github"

        if is_in_manifest(repo_path):
            print("Already exists: %s" % repo_path)
            continue

        print("Adding dependency:\nRepository: %s\nBranch: %s\nRemote: %s\nPath: %s\n" % (
            repo_name, repo_branch, repo_remote, repo_path))

        project = ElementTree.Element(
            "project",
            attrib={"path": repo_path,
                    "remote": repo_remote,
                    "name": "%s" % repo_name}
        )

        clone_depth = os.getenv('ROOMSERVICE_CLONE_DEPTH')
        if clone_depth:
            project.set('clone-depth', clone_depth)

        if repo_branch is not None:
            project.set('revision', repo_branch)
        elif fallback_branch:
            print("Using branch %s for %s" %
                  (fallback_branch, repo_name))
            project.set('revision', fallback_branch)
        else:
            print("Using default branch for %s" % repo_name)
        if 'clone-depth' in repo:
            print("Setting clone-depth to %s for %s" %
                  (repo['clone-depth'], repo_name))
            project.set('clone-depth', repo['clone-depth'])
        lm.append(project)

    indent(lm)
    raw_xml = "\n".join(('<?xml version="1.0" encoding="UTF-8"?>',
                         ElementTree.tostring(lm).decode()))

    f = open(custom_local_manifest, 'w')
    f.write(raw_xml)
    f.close()


_fetch_dep_cache = []


def fetch_dependencies(repo_path, fallback_branch=None):
    global _fetch_dep_cache
    if repo_path in _fetch_dep_cache:
        return
    _fetch_dep_cache.append(repo_path)

    print("Looking for dependencies")

    dep_path = os.path.join(repo_path, custom_dependencies)
    dep_p = glob(dep_path)
    if dep_p:
        print("Dependencies found")
        with open(dep_p[0]) as dep_f:
            dependencies = json.load(dep_f)
    else:
        dependencies = {}
        print("%s has no additional dependencies." % repo_path)

    fetch_list = []
    syncable_repos = []

    for dependency in dependencies:
        if not is_in_manifest(dependency['target_path']):
            if not dependency.get('branch'):
                dependency['branch'] = custom_default_revision

            fetch_list.append(dependency)
            syncable_repos.append(dependency['target_path'])
        else:
            print("Dependency already present in manifest: %s => %s" %
                  (dependency['repository'], dependency['target_path']))

    if fetch_list:
        print("Adding dependencies to manifest\n")
        add_to_manifest(fetch_list, fallback_branch)

    if syncable_repos:
        print("Syncing dependencies")
        os.system('repo sync --force-sync --no-tags --current-branch --no-clone-bundle %s' %
                  ' '.join(syncable_repos))

    for deprepo in syncable_repos:
        fetch_dependencies(deprepo)


def main():
    global DEBUG
    os.chdir(ROMREPO_DIR)

    if os.getenv('ROOMSERVICE_DEBUG'):
        DEBUG = True

    manufacturer = sys.argv[1]
    device = sys.argv[2]
    dt_repo = os.getenv('DT_REPO')
    dt_branch = os.getenv('DT_BRANCH')
    fallback_branch = custom_default_revision

    print("Attempting to retrieve device repository from GitHub.")

    if (dt_repo.startswith("https://github.com") and
            dt_repo.endswith(device + ".git")):
        repo_name = dt_repo[19:-4]
    elif (dt_repo.startswith("https://github.com") and
            dt_repo.endswith(device)):
        repo_name = dt_repo[19:]
    else:
        print("Invalid GitHub repository url for %s." % device)
        sys.exit(1)

    repo_path = "device/%s/%s" % (manufacturer, device)
    adding = [{'repository': repo_name, 'target_path': repo_path, 'branch': dt_branch}]

    add_to_manifest(adding, dt_branch)
    print("Syncing device repository.")
    os.system(
        'repo sync --force-sync --no-tags --current-branch --no-clone-bundle %s' % repo_path)
    print("Repository synced!")

    fetch_dependencies(repo_path, fallback_branch)
    print("Done")
    sys.exit()


if __name__ == "__main__":
    main()
