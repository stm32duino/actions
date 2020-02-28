#!/bin/bash

ROOT_SRC_PATH="$1"
IGNORE_LIST_PATH="$2"
ASTYLE_DEFINITION_PATH="$3"

OUTPUT_FILE="astyle-result.txt"
echo ::set-output name=astyle-result::$OUTPUT_FILE

if [ -z "$1" ]; then
  ROOT_SRC_PATH="."
fi

python3 /scripts/astyle.py -r "$ROOT_SRC_PATH" -i "$IGNORE_LIST_PATH" -d "$ASTYLE_DEFINITION_PATH" || {
  exit 1
}

RES=$([[ -f "astyle.out" ]] && grep -c "Formatted" < "astyle.out")
if [[ $RES -ne 0 ]]; then
  echo -e "AStyle check \e[31;1mfailed\e[0m, please fix style issues as shown below:" > "$OUTPUT_FILE"
  grep "Formatted" < "astyle.out" | tee -a "$OUTPUT_FILE"
  git --no-pager diff --color | tee -a "$OUTPUT_FILE"
  echo -e "AStyle check \e[31;1mfailed\e[0m, please fix style issues as shown above!"
  exit 1
else
  echo -e "AStyle check \e[32;1msucceeded\e[0m!" | tee "$OUTPUT_FILE"
fi