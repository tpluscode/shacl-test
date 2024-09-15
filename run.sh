#!/usr/bin/env bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
FAILED=0

filter=''

while [ $# -gt 0 ]; do
  case "$1" in
    --shapes=*)
      shapesPath="${1#*=}"
      ;;
    --approve)
      approvalsFlags='-f'
      ;;
    --filter=*)
      filter="${1#*=}"
      ;;
    --valid-cases=*)
      validCases="${1#*=}"
      ;;
    --invalid-cases=*)
      invalidCases="${1#*=}"
      ;;
    *)
      printf "*******************************************\n"
      printf "* Error: Invalid argument: %s *\n" "$1"
      printf "* Remember that the syntax is --arg=value *\n"
      printf "*******************************************\n"
      exit 1
  esac
  shift
done

# check if profile is set
if [ -z "$shapesPath" ]; then
  printf "*************************************\n"
  printf "* Error: --shapes argument missing. *\n"
  printf "*************************************\n"
  exit 1
fi

loadFullShape() {
  "$SCRIPT_PATH"/load-graph.js "$1" | "$SCRIPT_PATH"/pretty-print.js
}

# iterate over valid cases, run validation and monitor exit code
for file in $validCases; do
  name=$(basename "$file")

  # check if filter is set and skip if not matching
  if [ -n "$filter" ] && ! echo "$file" | grep -q "$filter"; then
    echo "ℹ️SKIP - $name"
    continue
  fi

  {
    if [ "$DEBUG" = true ]; then
      echo "🐞 npx b59 shacl validate --shapes $shapesPath < $file"
    fi
    npx shacl validate --shapes "$shapesPath" > "$file.log" 2>&1
    success=$?
  } < "$file"

  if [ $success -ne 0 ] ; then
    "$SCRIPT_PATH"/report-failure.sh "$file" "$(loadFullShape "$shapesPath")" "$(cat "$file")"
    FAILED=1
  else
    echo "✅ PASS - $name"
  fi
done

# iterate over invalid cases
for file in $invalidCases; do
  name=$(basename "$file")

  # skip if file does not exist
  if [ ! -f "$file" ]; then
    continue
  fi

  # check if pattern is set and skip if not matching
  if [ -n "$filter" ] && ! echo "$file" | grep -q "$filter"; then
    echo "ℹ️SKIP - $name"
    continue
  fi

    if [ "$DEBUG" = true ]; then
      echo "🐞 npx b59 shacl validate --shapes $shapesPath < $file"
    fi
  report=$(npx b59 shacl validate --shapes "$shapesPath" < "$file" 2> "$file.log" | "$SCRIPT_PATH"/pretty-print.js)

  if ! echo "$report" | npx approvals "$name" --outdir "$(basepath file)" "$approvalsFlags" > /dev/null 2>&1 ; then
    "$SCRIPT_PATH"/report-failure.sh "$file" "$(loadFullShape "$shapesPath")" "$(cat "$file")" "check results"
    FAILED=1
  else
    echo "✅ PASS - $name"
  fi
done

exit $FAILED
