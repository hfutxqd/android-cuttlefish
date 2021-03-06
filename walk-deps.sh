#!/bin/bash

set -o errexit
set -u
# set -x

# $1 = parent
# $2 = parent version
# $3 = name
# $4 = version
# $5 = op
# $6 = filter
# $7 = process

source utils.sh

function walk_deps {
  local parent="$1"
  local parent_version="$2"
  local name="${3/:any/}"
  local version="$4"
  local op="$5"
  local filter="$6"
  local process="$7"

  local package_and_arch=$(add_arch "${name}")

  if [ "${parent}" != '_' ]; then
    echo -n "${package_and_arch}," >> ignore-depends-for-${parent}.txt
  fi

  if [ -z "$(is_installed ${name} ${version} ${op})" ]; then
    return
  fi

  if ! grep -q -E "^${name}$|^${name} " deps.txt; then
    local installed_version=$(dpkg-query -W -f='${Version}' "${package_and_arch}")
    if [ "${version}" != '_' ]; then
      if ! dpkg --compare-versions ${installed_version} ${op} ${version}; then
        echo Installed package ${package_and_arch} version ${installed_version} not ${op} to/than ${version} 2>&1
        exit 1
      fi
    fi
    printf "%-${SHLVL}s" " "
    echo ${name} ${installed_version} | tee -a deps.txt
    ./parse-deps.sh "${name}" "${filter}" "${process}"
  fi
}

touch deps.txt
walk_deps $*
