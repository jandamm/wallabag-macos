#!/bin/sh

set -e

GIT=$(xcrun -find git)

PlistBuddy=/usr/libexec/PlistBuddy
INFO_PLIST="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.$1/Contents/Info.plist"

dir="$(dirname "$0")"
dir="$(cd "$dir" ; pwd -P )"

# Use the commit count before HEAD as CFBundleVersion
head_date="$("${GIT}" show -s --format=%cI)"
INFO_BUILD="$("${GIT}" rev-list --before "$head_date" head | wc -l | tr -d ' ')"

# Use the last annotated 'develop' tag as CFBundleShortVersionString
version=$("${GIT}" tag --merged HEAD --list 'v*' --sort=v:refname | tail -n 1)
INFO_VERSION=$(echo "$version" | sed 's/\-[0-9]*\-[a-zA-Z0-9]*//' | sed 's/^v//')

if [ -z "$INFO_VERSION" ]; then
	INFO_VERSION=$INFO_BUILD
fi

## Set Build/Version in Plists
if [ -x "$PlistBuddy" ]; then
	if [ -f "${INFO_PLIST}" ]; then
		$PlistBuddy -c "Set :CFBundleVersion ${INFO_BUILD}" "${INFO_PLIST}"
		# $PlistBuddy -c "Set :CFBundleShortVersionString ${INFO_VERSION}" "${INFO_PLIST}"
		$PlistBuddy -c "Save" "${INFO_PLIST}"
	else
		echo "error: ${INFO_PLIST} was not present"
		exit 1
	fi
else
	echo "error: PlistBuddy is not installed"
	exit 1
fi
