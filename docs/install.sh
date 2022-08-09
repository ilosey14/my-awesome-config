#!/bin/bash
# $0 [-f | --force]
# If you are having trouble building the awesomewm website from source,
# (or don't want to) this script will download the site for you.

ROOT_URL=https://awesomewm.org/apidoc # for `awesomewm-git`
INDEX=index.html
DIR=$HOME/.config/awesome/docs
IFS=$'\n'

cd "$DIR"

declare -A urls
force=$( [[ $1 == '-f' || $1 == '--force' ]] && echo true || echo false )

function for-each() {
	for i in $1
	do
		[[ -n $i ]] && $2 $i
	done
}

function xpath() {
	xmllint --html --quiet --xpath "$2" "$1" 2> /dev/null
}

function get() {
	local path=$( realpath -m $1 )

	# check if we've visited the link
	[[ -v urls[$path] ]] && return 0

	urls[$path]=

	# encode some paths that have spaces
	path=${1// /\%20}

	local from=$ROOT_URL/$path
	local to=$DIR/$path
	local to_dir=$( dirname $path )

	# get page
	if [[ ! -f $to ]] || $force
	then
		echo $( $force && echo '[FORCE] ' )"GET $from -> $to"
		curl -sSL -o "$to" --create-dirs "$from" || return 1
	fi

	# links
	hrefs=$( xpath "$to" '/html/head/link/@href' | grep -Eo '".+"' | cut -d\" -f2 | xargs -i echo "$to_dir/{}" )
	for-each "${hrefs[@]}" get

	# images
	srcs=$( xpath "$1" '//img/@src' | grep -Eo '".+"' | cut -d\" -f2 | xargs -i echo "$to_dir/{}" )
	for-each "${srcs[@]}" get
}

# get docs index
get $INDEX

# parse all urls in TOC to get pages
indices=$( xpath $INDEX '//*[@id="navigation"]//a/@href' | grep -Eo '"(.+)"' | cut -d\" -f2 )
for-each "${indices[@]}" get
