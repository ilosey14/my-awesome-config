#!/bin/bash
# $0 [--force]
# unicode emoji versions: https://unicode.org/Public/emoji/
# unicode.txt source file: https://unicode.org/Public/emoji/<version>/emoji-test.txt

IN_FILE=$DIR/unicode.txt
OUT_FILE=$DIR/emoji.txt

if [[ ! -f $IN_FILE ]]
then
	echo "# Missing unicode source \"$IN_FILE\"."
	exit
fi

# check if the unicode source is newer than the build

if [[ $1 != '--force' && -f $OUT_FILE ]]
then
	echo '# Checking previous build time...'

	in_file_mod=$( stat -c %Y $IN_FILE )
	out_file_mod=$( stat -c %Y $OUT_FILE )

	if [[ $out_file_mod -gt $in_file_mod ]]
	then
		echo '# Build target is newer than source. Exiting.'
		exit
	fi

	echo '# ... rebuild needed.'
else
	echo '# Forcing rebuild...'
fi

# convert unicode source to a lua table
echo '# Building source...'
echo "-- auto-generated from $IN_FILE" > $OUT_FILE

awk \
'BEGIN {
	FS=" {2,}[;#] | E[0-9]+.[0-9]+ |: "
	OFS = ""
	first = 1
}
/^# group/ {
	if (first) first = 0
	else print "},"

	print "{\nname = \"", $2, "\","
}
$2 != "fully-qualified" { next }
/^[^#]/ {
	split($1,codes," ")
	print "{ \"", $3, "\", \"", $4, "\"", (codes[1] == last_code) ? ", true" : "", " },"
	last_code=codes[1]
}
END { print "}\n" }' \
	$IN_FILE >> $OUT_FILE
