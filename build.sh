#!/bin/bash
# SANDMAN - BUILD SCRIPT

# Release path: compiled, minified
SANDMAN_RELEASE_PATH="./release"
SANDMAN_RELEASE_NAME="sandman_min.lua"
# Debug path: compiled, unminified
SANDMAN_DEBUG_PATH="./debug"
SANDMAN_DEBUG_NAME="sandman_debug.lua"

# The path to the source files
SANDMAN_SRC_PATH="./src"

# Edit these lines to add new source files to the build.
# Files are added in the order that they are listed.
SANDMAN_LOADER_INCLUDE=("util.lua" "settings.lua" "time.lua" "model.lua" "init.lua" "display.lua" "api.lua" "update.lua" "editor.lua" "wizard.lua")

# -------DO NOT EDIT BELOW THIS LINE--------
SANDMAN_LOADERINIT="xx_loader.lua"
SANDMAN_COMMENTS="xx_comments.lua"
SANDMAN_FINALINIT="xx_finalinit.lua"

if [ "$1" = "debug" ]; then
    SANDMAN_BUILD_PATH="$SANDMAN_DEBUG_PATH"
    SANDMAN_FINAL_PATH="$SANDMAN_DEBUG_PATH/$SANDMAN_DEBUG_NAME"
else
    SANDMAN_BUILD_PATH="$SANDMAN_RELEASE_PATH"
    SANDMAN_FINAL_PATH="$SANDMAN_RELEASE_PATH/$SANDMAN_RELEASE_NAME"
fi

mkdir tmp
if [ -d $SANDMAN_BUILD_PATH ]; then
    if [ -f $SANDMAN_FINAL_PATH ]; then
        rm $SANDMAN_FINAL_PATH
    fi
else
    mkdir $SANDMAN_BUILD_PATH
fi

# build SANDMAN loader
for f in ${SANDMAN_LOADER_INCLUDE[@]}; do
    cat $SANDMAN_SRC_PATH/$f >> tmp/header.lua
    printf "\n\n" >> tmp/header.lua
done
cat tmp/header.lua > tmp/loader.lua
if [ "$1" = "debug" ]; then
    cat tmp/loader.lua > tmp/loader_min.lua
else
    luamin -f tmp/loader.lua > tmp/loader_min.lua
fi

# build the escape string for loading
python3 escape.py tmp/loader_min.lua tmp/loader_escaped.txt

# finalize
cat $SANDMAN_SRC_PATH/$SANDMAN_LOADERINIT >> tmp/header.lua
cat tmp/loader_escaped.txt >> tmp/header.lua
cat $SANDMAN_SRC_PATH/$SANDMAN_FINALINIT >> tmp/header.lua

# combine into final compiled minified lua
if [ "$1" = "debug" ]; then
    cat tmp/header.lua > tmp/final_min.lua
else
    luamin -f tmp/header.lua > tmp/final_min.lua
fi

cat $SANDMAN_SRC_PATH/$SANDMAN_COMMENTS > $SANDMAN_FINAL_PATH
printf "\n\n" >> $SANDMAN_FINAL_PATH
cat tmp/final_min.lua >> $SANDMAN_FINAL_PATH

echo "Success! SANDMAN has been compiled to $SANDMAN_FINAL_PATH."

# clear the temporary directory
rm -rf tmp
