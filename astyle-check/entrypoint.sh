#!/bin/bash

ROOT_SRC_PATH="$1"
readonly IGNORE_LIST_PATH="$2"
readonly ASTYLE_DEFINITION_PATH="$3"

readonly OUTPUT_FILE="astyle-result.txt"
echo "astyle-result=$OUTPUT_FILE" >>"$GITHUB_OUTPUT"

if [ -z "$1" ]; then
  ROOT_SRC_PATH="."
fi

SCRIPT_PATH="./"

# Is it the STM32 core to check?
if [ -d "$GITHUB_WORKSPACE/cores" ] && [ -d "$GITHUB_WORKSPACE/variants" ]; then
  # script available locally
  SCRIPT_PATH="$GITHUB_WORKSPACE/CI/astyle"
else
  # Ensure to have the latest script version and linked files
  wget --no-verbose https://github.com/stm32duino/Arduino_Core_STM32/raw/main/CI/astyle/astyle.py
  wget --no-verbose https://github.com/stm32duino/Arduino_Core_STM32/raw/main/CI/astyle/.astyleignore
  wget --no-verbose https://github.com/stm32duino/Arduino_Core_STM32/raw/main/CI/astyle/.astylerc
fi

python3 "$SCRIPT_PATH"/astyle.py -r "$ROOT_SRC_PATH" -i "$IGNORE_LIST_PATH" -d "$ASTYLE_DEFINITION_PATH" || {
  exit 1
}

RES=$([[ -f "astyle.out" ]] && grep --count "Formatted" <"astyle.out")
if [[ $RES -ne 0 ]]; then
  git config --global --add safe.directory "$GITHUB_WORKSPACE"
  echo -e "AStyle check \e[31;1mfailed\e[0m, please fix style issues as shown below:" >"$OUTPUT_FILE"
  grep "Formatted" <"astyle.out" | tee --append "$OUTPUT_FILE"
  git --no-pager diff --color | tee --append "$OUTPUT_FILE"
  echo -e "AStyle check \e[31;1mfailed\e[0m, please fix style issues as shown above!"
  exit 1
else
  echo -e "AStyle check \e[32;1msucceeded\e[0m!" | tee "$OUTPUT_FILE"
fi
