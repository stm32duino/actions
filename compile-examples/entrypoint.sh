#!/bin/bash

BOARDS_PATTERN=$1
CLI_VERSION=$2
LIBRARIES=$3

CORE_PATH=$HOME/.arduino15/packages/STM32/hardware/stm32
LIBRARIES_PATH=$HOME/Arduino/libraries
EXAMPLES_FILE=examples.txt
OUTPUT_FILE=compile-result.txt
echo ::set-output name=compile-result::$OUTPUT_FILE

# Determine cli archive
CLI_ARCHIVE=arduino-cli_${CLI_VERSION}_Linux_64bit.tar.gz

# Additional Boards Manager URL
ADDITIONAL_URL="https://github.com/stm32duino/BoardManagerFiles/raw/master/STM32/package_stm_index.json"

# Download the arduino-cli
wget --no-verbose -P $HOME https://downloads.arduino.cc/arduino-cli/$CLI_ARCHIVE

# Extract the arduino-cli to $HOME/bin
mkdir $HOME/bin
tar xf $HOME/$CLI_ARCHIVE -C $HOME/bin

# Other way to install arduino-cli but only the latest one
# curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh

# Add arduino-cli to the PATH
export PATH=$PATH:$HOME/bin

# Update the code index and install the required CORE
arduino-cli core update-index --additional-urls $ADDITIONAL_URL
arduino-cli core install STM32:stm32 --additional-urls $ADDITIONAL_URL

# Install libraries if needed
if [ -z "$LIBRARIES" ]; then
  echo "No libraries to install"
else
  IFS=',' read -ra LIB_NAME <<< "$LIBRARIES"
  for i in "${LIB_NAME[@]}"; do
    # Ensure no leading/trailing spaces
    iws=`echo $i | sed -e 's/^[[:space:]]*//'`
    arduino-cli lib install "$iws"
  done
fi

# Symlink the library that needs to be built in the sketchbook
mkdir -p $LIBRARIES_PATH
ln -s $GITHUB_WORKSPACE $LIBRARIES_PATH/.

CORE_VERSION=`eval ls $CORE_PATH`
CORE_VERSION_PATH=$CORE_PATH/$CORE_VERSION
SCRIPT_PATH=$CORE_VERSION_PATH/CI/build

# Is it the STM32 core to build ?
if [ -d "$GITHUB_WORKSPACE/cores" ] && [ -d "$GITHUB_WORKSPACE/variants" ]; then
  # Symlink core
  rm -r $CORE_PATH/*
  ln -s $GITHUB_WORKSPACE $CORE_VERSION_PATH
  find $SCRIPT_PATH/examples -name '*.ino' | xargs dirname | uniq > $EXAMPLES_FILE
else
  # Create file of all examples to build
  if [ -d "examples" ]; then
    find examples -name '*.ino' | xargs dirname | uniq > $EXAMPLES_FILE
  else
    touch $EXAMPLES_FILE
  fi
fi

# arduino-cli.py will be available on core version 1.9.0
# Fallback to the embedded one if not exists
# Check if arduino-cli.py available
if [ ! -f $SCRIPT_PATH/arduino-cli.py ]; then
  SCRIPT_PATH=/scripts
fi

# Build all examples
if [ -z "$BOARDS_PATTERN" ]; then
  python3 $SCRIPT_PATH/arduino-cli.py --ci -f $EXAMPLES_FILE | tee $OUTPUT_FILE
else
  python3 $SCRIPT_PATH/arduino-cli.py --ci -f $EXAMPLES_FILE -b "$BOARDS_PATTERN" | tee $OUTPUT_FILE
fi

exit ${PIPESTATUS[0]}
