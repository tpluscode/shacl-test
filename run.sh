#!/usr/bin/env bash

SCRIPT_PATH="$(dirname "$(realpath "$0")")"
WORKING_DIR="$(pwd)"
FAILED=0

filter=''
debug=false
prefixes=()
command="npx barnard59 shacl validate --shapes"

while [ $# -gt 0 ]; do
  case "$1" in
    --shapes=*)
      shapesPath="${1#*=}"
      ;;
    --approve)
      approvalsFlags='-f'
      ;;
    --debug)
      debug=true
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
    --prefixes=*)
      IFS=',' read -r -a tempPrefixes <<< "${1#*=}"
      prefixes+=("${tempPrefixes[@]}")
      ;;
    --command=*)
      command="${1#*=}"
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

# check if shapesPath is set
if [ -z "$shapesPath" ]; then
  printf "*************************************\n"
  printf "* Error: --shapes argument missing. *\n"
  printf "*************************************\n"
  exit 1
fi

command="$command $shapesPath"
if [ "$debug" = true ]; then
  echo "🐞 Command: $command"
  echo "🐞 Filter: $filter"
  echo "🐞 Approval flags: $approvalsFlags"
  echo ""
fi

loadFullShape() {
  "$SCRIPT_PATH"/load-graph.js "$1" | "$SCRIPT_PATH"/pretty-print.js --prefixes "${prefixes[@]}"
}

# iterate over valid cases, run validation and monitor exit code
for file in $validCases; do
  name=$(basename "$file")
  relativePath=$(node -e "console.log(require('path').relative('$WORKING_DIR', '$file'))")

  # check if filter is set and skip if not matching
  if [ -n "$filter" ] && ! echo "$file" | grep -q "$filter"; then
    echo "ℹ️SKIP - $relativePath"
    continue
  fi

  {
    sh -c "$command" > "$file.log" 2>&1
    success=$?
  } < "$file"

  if [ $success -ne 0 ] ; then
    "$SCRIPT_PATH"/report-failure.sh "$file" "$(loadFullShape "$shapesPath")" "$(cat "$file")"
    FAILED=1
  else
    echo "✅ PASS - $relativePath"
  fi
done

# iterate over invalid cases
for file in $invalidCases; do
  name=$(basename "$file")
  relativePath=$(node -e "console.log(require('path').relative('$WORKING_DIR', '$file'))")

  # skip if file does not exist
  if [ ! -f "$file" ]; then
    continue
  fi

  # check if pattern is set and skip if not matching
  if [ -n "$filter" ] && ! echo "$file" | grep -q "$filter"; then
    echo "ℹ️SKIP - $relativePath"
    continue
  fi

  report=$(sh -c "$command" < "$file" 2> "$file.log" | "$SCRIPT_PATH"/pretty-print.js --prefixes "${prefixes[@]}")

  if ! echo "$report" | npx approvals "$name" --outdir "$(dirname "$file")" "$approvalsFlags" > /dev/null 2>&1 ; then
    "$SCRIPT_PATH"/report-failure.sh "$file" "$(loadFullShape "$shapesPath")" "$(cat "$file")" "check results"
    FAILED=1
  else
    echo "✅ PASS - $name"
  fi
done

exit $FAILED
