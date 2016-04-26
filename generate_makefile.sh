#!/bin/bash

# Simple Makefile generator for C++ - projects.

# Warning: Doesn't allow names with spaces.
# Use `_` instead.

# Warning: Doesn't support multiple projects in one folder with different `main` functions.

ZIP_EXT='cpp hpp h'

STD='c++1z'

BUILD_OUT='g++ $^ -o $@'
BUILD_O_RELEASE='g++ -O3 -c -Wfatal-errors -std=$(STD) $< -o $@'
BUILD_O_DEBUG='g++ -c -Wall -std=$(STD) -D _GLIBCXX_DEBUG -g -Wextra -Wshadow -Wpedantic -Wfatal-errors $< -o $@'

function dirfix {
    tmp="$(dirname "$1")/"
    printf "${tmp#./}"
}

function cpp2o {
    printf "$(dirfix "$1")$(basename "$1" .cpp).o"
}

function parse {
    result="$1"
    cur="$1"
    declare -A used
    while [ "$cur" ]
    do
        next=""
        for file in $cur
        do
            dep=$(grep -P "^#include \".+\"$" "$file" | grep -Po "\".+\"" | grep -Po "[^\"]+" | tr "\n" " ")
            dir_name="$(dirfix $file)"

            for x in $dep
            do
                x="$dir_name$x"
                if [ ! "${used[$x]}" ]
                then
                    used[$x]=true
                    next+=" $x"
                    result+=" $x"
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

while read file
do
    if [ "$file" ]
    then
        o_name="$(cpp2o "$file")"

        debug_files+=" debug/$o_name"
        release_files+=" release/$o_name"

        parsed="$(parse "$file")"
        dir_name="$(dirfix "$file")"

        debug_hierarchy+="
debug/$o_name: $parsed
\tmkdir -p \"debug/$dir_name\" 2> /dev/null || true
\t\$(BUILD_O_DEBUG)
"

        release_hierarchy+="
release/$o_name: $parsed
\tmkdir -p \"release/$dir_name\" 2> /dev/null || true
\t\$(BUILD_O_RELEASE)
"
    fi
done <<< "$(find -name "*.cpp")"

to_zip=""

for ext in $ZIP_EXT
do
    while read file
    do
        if [ "$file" ]
        then
            to_zip+=" $file"
        fi
    done <<< "$(find -name "*.$ext")"
done

if true
then
    echo -e "# Automatically generated."
    echo -e "# Useful targets: release, debug, clean, zip."
    echo -e "# Executable files: \`debug/a.out\` and \`release/a.out\`."
    echo -e ""
    echo -e "STD = $STD"
    echo -e ""
    echo -e "BUILD_O_RELEASE = $BUILD_O_RELEASE"
    echo -e "BUILD_O_DEBUG = $BUILD_O_DEBUG"
    echo -e "BUILD_OUT = $BUILD_OUT"
    echo -e ""
    echo -e ".PHONY: default release debug clean zip"
    echo -e ""
    echo -e "default: debug"
    echo -e ""
    echo -e "# release:"
    echo -e ""
    echo -e "release: release/a.out"
    echo -e ""
    echo -e "release/a.out:$release_files"
    echo -e "\tmkdir -p release || true"
    echo -e "\t\$(BUILD_OUT)"
    echo -e "$release_hierarchy"
    echo -e ""
    echo -e "# debug:"
    echo -e ""
    echo -e "debug: debug/a.out"
    echo -e ""
    echo -e "debug/a.out:$debug_files"
    echo -e "\tmkdir -p debug || true"
    echo -e "\t\$(BUILD_OUT)"
    echo -e "$debug_hierarchy"
    echo -e ""
    echo -e "# other:"
    echo -e ""
    echo -e "clean:"
    echo -e "\trm -r debug release 2> /dev/null || true"
    echo -e "\tfind \\( -name \"*.out\" -or -name \"*.o\" -or -name \"*.tmp\" -or -name \"*.zip\" \\) -and -delete"
    echo -e ""
    echo -e "zip:"
    echo -e "\tzip result.zip$to_zip"
    echo -e ""

fi > "Makefile"
