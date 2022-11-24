#!/bin/bash

readonly BOARDS_PATTERN="$1"
readonly CLI_VERSION="$2"
readonly LIBRARIES="$3"
readonly ADDITIONAL_URL="$4"
readonly EXAMPLE_PATTERN="$5"
readonly CUSTOM_CONFIG="$6"

readonly CORE_PATH="$HOME/.arduino15/packages/STMicroelectronics/hardware/stm32"
readonly LIBRARIES_PATH="$HOME/Arduino/libraries"
readonly EXAMPLES_FILE="examples.txt"
readonly OUTPUT_FILE="compile-result.txt"
echo "compile-result=$OUTPUT_FILE" >>"$GITHUB_OUTPUT"

# Determine cli archive
readonly CLI_ARCHIVE="arduino-cli_${CLI_VERSION}_Linux_64bit.tar.gz"

options=(--ci -f "$EXAMPLES_FILE")

# Download the arduino-cli
wget --no-verbose --directory-prefix="$HOME" "https://downloads.arduino.cc/arduino-cli/$CLI_ARCHIVE" || {
  exit 1
}
# Extract the arduino-cli to $HOME/bin
mkdir "$HOME/bin"
tar --extract --file="$HOME/$CLI_ARCHIVE" --directory="$HOME/bin" || {
  exit 1
}

# Other way to install arduino-cli but only the latest one
# curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh

# Add arduino-cli to the PATH
export PATH=$PATH:$HOME/bin

# Update the code index and install the required CORE
arduino-cli config init --additional-urls "$ADDITIONAL_URL"
arduino-cli core update-index
arduino-cli core install STMicroelectronics:stm32 || {
  exit 1
}

# Install libraries if needed
if [ -z "$LIBRARIES" ]; then
  echo "No libraries to install"
else
  IFS=',' read -ra LIB_NAME <<<"$LIBRARIES"
  for i in "${LIB_NAME[@]}"; do
    # Ensure no leading/trailing spaces
    iws=$(echo "$i" | sed --expression='s/^[[:space:]]*//' --expression='s/[[:space:]]$//')
    arduino-cli lib install "$iws" || {
      exit 1
    }
  done
fi

# Symlink the library that needs to be built in the sketchbook
mkdir --parents "$LIBRARIES_PATH"
ln --symbolic "$GITHUB_WORKSPACE" "$LIBRARIES_PATH/." || {
  exit 1
}

CORE_VERSION=$(eval ls "$CORE_PATH")
readonly CORE_VERSION_PATH="$CORE_PATH/$CORE_VERSION"
SCRIPT_PATH="$CORE_VERSION_PATH/CI/build"
EXAMPLES_PATH="examples"

# Is it the STM32 core to build ?
if [ -d "$GITHUB_WORKSPACE/cores" ] && [ -d "$GITHUB_WORKSPACE/variants" ]; then
  # Symlink core
  rm --recursive "${CORE_PATH:?}/"*
  ln --symbolic "$GITHUB_WORKSPACE" "$CORE_VERSION_PATH" || {
    exit 1
  }
  EXAMPLES_PATH="$SCRIPT_PATH/examples"
else
  # Ensure to have the latest script version
  wget --no-verbose -O "$SCRIPT_PATH/arduino-cli.py" https://github.com/stm32duino/Arduino_Core_STM32/raw/main/CI/build/arduino-cli.py
  if [ ! -d "$EXAMPLES_PATH" ]; then
    echo -e "\e[33;1mNo example to compile for this repository!\e[0m"
    echo -e "\e[33;1mFallback to Arduino libraries folder...\e[0m"
    EXAMPLES_PATH="$LIBRARIES_PATH"
  fi
fi

# Create file of all examples to build
find "$EXAMPLES_PATH" -name '*.ino' -exec dirname {} + | uniq >"$EXAMPLES_FILE.bak"
if ! grep -e "$EXAMPLE_PATTERN" "$EXAMPLES_FILE.bak" >"$EXAMPLES_FILE" 2>&1; then
  echo -e "\e[31;1mFailed to find example!\e[0m"
  exit 1
fi

# Check if arduino-cli.py available
if [ ! -f "$SCRIPT_PATH/arduino-cli.py" ]; then
  echo -e "\e[31;1marduino-cli.py could not be found!\e[0m"
  exit 1
fi

# Check if arduino-cli.py manages url argument
if grep "args.url" "$SCRIPT_PATH/arduino-cli.py" >/dev/null 2>&1; then
  options+=(--url "$ADDITIONAL_URL")
fi

if [ -n "$BOARDS_PATTERN" ]; then
  options+=(-b "$BOARDS_PATTERN")
fi

if [ -n "$CUSTOM_CONFIG" ]; then
  if [ ! -f "$CUSTOM_CONFIG" ]; then
    echo -e "\e[33;1m${CUSTOM_CONFIG} could not be found!\e[0m"
    echo -e "\e[33;1mFallback to default configuratuion...\e[0m"
  else
    options+=(--config "$CUSTOM_CONFIG")
  fi
fi

# Build all examples
python3 "$SCRIPT_PATH/arduino-cli.py" "${options[@]}" | tee "$OUTPUT_FILE"

exit "${PIPESTATUS[0]}"
