#!/usr/bin/env bash
##? Install a package
##?
##? Usage:
##?    $0 [--pkgmgr <package_manager>] <packages_names>...
eval "$(docpars -h "$(grep "^##?" "$0" | cut -c 5-)" : "$@")"
echo "pkgmgr: $pkgmgr"
echo "package_manager: $package_manager"
echo "packages: ${packages_names[*]}"
echo