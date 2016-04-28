#!/bin/bash

# Simple Makefile generator for C++ - projects.

# Warning: Doesn't allow names with spaces.
# Use `_` instead.

SOURCE="src"
TEST="test"
BIN="bin"

EXE="main"

DEFAULT="release"

STD='c++1z'

BUILD_OUT='g++ $^ -o $@'
BUILD_O_RELEASE='g++ -O3 -c -Wfatal-errors -std=$(STD) $< -o $@'
BUILD_O_DEBUG='g++ -c -Wall -std=$(STD) -D _GLIBCXX_DEBUG -g -Wextra -Wshadow -Wpedantic -Wfatal-errors $< -o $@'

releasebin="$BIN/release"
debugbin="$BIN/debug"
testbin="$BIN/test"

function pathfix {
    tmp="$1"
    printf "${tmp#./}"
}

function dirfix {
    tmp="$(dirname "$1")/"
    printf "${tmp#./}"
}

function cpp2o {
    printf "$(dirfix "$1")$(basename "$1" .cpp).o"
}

# Usage: parse prefix file
function parse {
    pref="$1"
    result=""
    cur="$(pathfix "$2")"
    declare -A used
    while [ "$cur" ]
    do
        next=""
        for file in $cur
        do
            result+=" $pref/$file"

            dep=$(grep -P "^#include \".+\"$" "$file" | grep -Po "\".+\"" | grep -Po "[^\"]+" | tr "\n" " ")
            dir_name="$(dirfix $file)"

            for x in $dep
            do
                x="$dir_name$x"
                if [ ! "${used[$x]}" ]
                then
                    used[$x]=true
                    next+=" $x"
                fi
            done
        done
        cur="$next"
    done
    printf "$result"
}

debug_files=""
release_files=""
debug_hierarchy=""

cd $SOURCE;
while read file
do
    if [ "$file" ]
    then
        o_name="$(cpp2o "$file")"

        debug_files+=" $debugbin/$o_name"
        release_files+=" $releasebin/$o_name"

        parsed="$(parse "$SOURCE" "$file")"
        dir_name="$(dirfix "$file")"

        debug_hierarchy+="
$debugbin/$o_name:$parsed
\tmkdir -p \"$debugbin/$dir_name\" 2> /dev/null || true
\t\$(BUILD_O_DEBUG)
"

        release_hierarchy+="
$releasebin/$o_name:$parsed
\tmkdir -p \"$releasebin/$dir_name\" 2> /dev/null || true
\t\$(BUILD_O_RELEASE)
"
    fi
done <<< "$(find -name "*.cpp")"
cd ..

test_files=""
test_hierarchy=""

cd test
while read file
do
    if [ "$file" ]
    then
        o_name="$(cpp2o "$file")"

        test_files+=" $testbin/$o_name"

        parsed="$(parse "test" "$file")"
        dir_name="$(dirfix "$file")"

        test_hierarchy+="
$testbin/$o_name: $parsed
\tmkdir -p \"$testbin/$dir_name\" 2> /dev/null || true
\t\$(BUILD_O_DEBUG)
"

    fi
done <<< "$(find -name "*.cpp")"
cd ..

if true
then
    echo -e "# Automatically generated."
    echo -e "# Useful targets: release, debug, test, clean."
    echo -e "# Executable files: \`$debugbin/$EXE/\`, \`$releasebin/$EXE\`, \`$testbin/main\`."
    echo -e ""
    echo -e "STD = $STD"
    echo -e ""
    echo -e "BUILD_O_RELEASE = $BUILD_O_RELEASE"
    echo -e "BUILD_O_DEBUG = $BUILD_O_DEBUG"
    echo -e "BUILD_OUT = $BUILD_OUT"
    echo -e ""
    echo -e ".PHONY: default release debug test clean"
    echo -e ""
    echo -e "default: $DEFAULT"
    echo -e ""
    echo -e "# release:"
    echo -e ""
    echo -e "release: $releasebin/$EXE"
    echo -e ""
    echo -e "$releasebin/$EXE:$release_files"
    echo -e "\tmkdir -p $releasebin || true"
    echo -e "\t\$(BUILD_OUT)"
    echo -e "$release_hierarchy"
    echo -e ""
    echo -e "# debug:"
    echo -e ""
    echo -e "debug: $debugbin/$EXE"
    echo -e ""
    echo -e "$debugbin/$EXE:$debug_files"
    echo -e "\tmkdir -p $debugbin || true"
    echo -e "\t\$(BUILD_OUT)"
    echo -e "$debug_hierarchy"
    echo -e ""
    echo -e "# test:"
    echo -e ""
    echo -e "test: $testbin/main"
    echo -e ""
    echo -e "$testbin/main:$test_files"
    echo -e "\tmkdir -p $testbin || true"
    echo -e "\t\$(BUILD_OUT)"
    echo -e "$test_hierarchy"
    echo -e ""
    echo -e "# other:"
    echo -e ""
    echo -e "clean:"
    echo -e "\trm -r bin 2> /dev/null || true"
    echo -e "\tfind \\( -name \"*.out\" -or -name \"*.o\" -or -name \"*.tmp\" -or -name \"*.zip\" \\) -and -delete"
    echo -e ""

fi > "Makefile"
