#!/bin/bash

readonly BOARDS_PATTERN="$1"
readonly CLI_VERSION="$2"
readonly LIBRARIES="$3"
readonly ADDITIONAL_URL="$4"
readonly EXAMPLE_PATTERN="$5"
readonly CUSTOM_CONFIG="$6"
readonly USE_CORE_REPO="$7"

readonly CORE_PATH="$HOME/.arduino15/packages/STMicroelectronics/hardware/stm32"
readonly LIBRARIES_PATH="$HOME/Arduino/libraries"
readonly EXAMPLES_FILE="examples.txt"
readonly OUTPUT_FILE="compile-result.txt"
echo "compile-result=$OUTPUT_FILE" >>"$GITHUB_OUTPUT"

# Use python venv
python3 -m venv "$HOME/venv"
source "$HOME/venv/bin/activate"
python3 -m pip install --quiet --upgrade packaging

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
CORE_VERSION=$(eval ls "$CORE_PATH")
readonly CORE_VERSION_PATH="$CORE_PATH/$CORE_VERSION"

# Scan PR comments for the keyword: /use-core-pr <number>
# The last occurrence wins (most recent comment takes precedence)
CORE_PR_NUMBER=""
if [ -n "$GITHUB_TOKEN" ] && [ -n "$GITHUB_REPOSITORY" ] && [ -f "${GITHUB_EVENT_PATH:-}" ]; then
  PR_NUMBER=$(python3 -c "
import json, sys
try:
    d = json.load(open('$GITHUB_EVENT_PATH'))
    print(d.get('pull_request', d.get('issue', {})).get('number', ''))
except Exception:
    pass
" 2>/dev/null)
  if [ -n "$PR_NUMBER" ]; then
    echo "Scanning PR #$PR_NUMBER body for /use-core-pr keyword..."
    CORE_PR_NUMBER=$(gh api "repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER" --jq '.body // ""' 2>/dev/null | python3 -c "
import sys, re
matches = re.findall(r'(?i)/use-core-pr\s+#?(\d+)', sys.stdin.read())
if matches:
    print(matches[-1])
" 2>/dev/null || true)
    if [ -n "$CORE_PR_NUMBER" ]; then
      echo "Found core PR reference: #$CORE_PR_NUMBER"
    fi
  fi
fi

if [ -n "$CORE_PR_NUMBER" ] || [ "$USE_CORE_REPO" = "true" ]; then
  # Remove the existing core and replace it with the repository version
  # Important note: using latest version from the repository may introduce some new dependencies.
  # It is advised to set the additional URL to the dev branch of the board manager file to ensure
  # compatibility with the main branch of the core:
  # additional-url: 'https://github.com/stm32duino/BoardManagerFiles/raw/dev/package_stmicroelectronics_index.json'
  rm -rf "$CORE_VERSION_PATH"
  if [ -n "$CORE_PR_NUMBER" ]; then
    # Clone without --depth 1 to allow gh pr checkout to fetch the PR ref
    gh repo clone stm32duino/Arduino_Core_STM32 "$CORE_VERSION_PATH" -- --recurse-submodules || {
      exit 1
    }
    echo "Checking out core PR #$CORE_PR_NUMBER..."
    (cd "$CORE_VERSION_PATH" && gh pr checkout "$CORE_PR_NUMBER") || {
      exit 1
    }
    (cd "$CORE_VERSION_PATH" && git submodule update --init --recursive) || {
      exit 1
    }
  else
    # Clone the main branch
    gh repo clone stm32duino/Arduino_Core_STM32 "$CORE_VERSION_PATH" -- --recurse-submodules --depth 1 || {
      exit 1
    }
  fi
fi


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
