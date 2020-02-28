#!/bin/bash

ROOT_SRC_PATH="$1"
readonly IGNORE_LIST_PATH="$2"
readonly ASTYLE_DEFINITION_PATH="$3"

readonly OUTPUT_FILE="astyle-result.txt"
echo ::set-output name=astyle-result::$OUTPUT_FILE

if [ -z "$1" ]; then
  ROOT_SRC_PATH="."
fi

python3 /scripts/astyle.py -r "$ROOT_SRC_PATH" -i "$IGNORE_LIST_PATH" -d "$ASTYLE_DEFINITION_PATH" || {
  exit 1
}

RES=$([[ -f "astyle.out" ]] && grep --count "Formatted" <"astyle.out")
if [[ $RES -ne 0 ]]; then
  echo -e "AStyle check \e[31;1mfailed\e[0m, please fix style issues as shown below:" >"$OUTPUT_FILE"
  grep "Formatted" <"astyle.out" | tee --append "$OUTPUT_FILE"
  git --no-pager diff --color | tee --append "$OUTPUT_FILE"
  echo -e "AStyle check \e[31;1mfailed\e[0m, please fix style issues as shown above!"
  exit 1
else
  echo -e "AStyle check \e[32;1msucceeded\e[0m!" | tee "$OUTPUT_FILE"
fi
