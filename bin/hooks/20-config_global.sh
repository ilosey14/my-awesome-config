#!/bin/bash
# aggregate global config files

echo CONFIG_NAME=keys

function fmod() {
	[[ -z "$1" ]] && return
	stat -c %Y "$1"
}

# keys

KEYS_FILE=keys.conf
TARGET_PATH="$DIR/$KEYS_FILE"

key_paths=()
key_modified=

[[ -f "$TARGET_PATH" ]] || touch "$TARGET_PATH"

while read filename
do
	# skip target
	[[ "$filename" == "$TARGET_PATH" ]] && continue

	# append lib.config path
	no_ext=${filename/.conf}     # remove conf extension
	all_dots=${no_ext//\//.}     # convert slashes to dots
	key_paths+=("${all_dots:2}") # remove first two dots

	# check for most recent modified date
	modified=$( fmod "$filename" )

	[[ $modified -gt $keys_modified ]] && key_modified=$modified
done < <( find -name $KEYS_FILE )

key_num=${#key_paths[@]}

if [[ $key_num -le 0 ]]
then
	echo '# No key config files found. Exiting.'
	exit
fi

# force build
if [[ $1 != '--force' && $keys_modified -lt $( fmod $TARGET_PATH ) ]]
then
	echo '# Build target is newer than source files. Exiting'
	exit
fi

echo "# Compiling $key_num key config files..."

# format paths as a lua table

sep="','"
key_paths_joined=$( printf "${sep}%s" ${key_paths[@]} )
key_paths_array="'${key_paths_joined:${#sep}}'"

# config

awesome-client << EOF
local config = require('lib.config')
local f, err = io.open('$( realpath $TARGET_PATH )', 'w+')
if not f then return err end
for _, path in ipairs {$key_paths_array} do
	local c = config.load(path)
	for _, bind in ipairs(c) do
		f:write('{\n')
		f:write(config.serialize(bind))
		f:write('},\n')
	end
end
f:close()
EOF
