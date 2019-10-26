#!/bin/bash
set -eu -o pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

outfile_tree=/tmp/maven-deps/tree
outfile_flat=/tmp/maven-deps/flat

rm -rf /tmp/maven-deps

mvn dependency:tree -q -DoutputFile="$outfile_tree" -DappendOutput=true

cat "$outfile_tree" \
  | grep ' ' \
  | sed 's/.* //' \
  | sed 's/:[^:]\+$//' \
  | sort \
  | uniq \
  >"$outfile_flat"

count_all=$(cat "$outfile_flat" | wc -l)

count_ignore_version=$(
  cat "$outfile_flat" \
    | sed 's/:[^:]\+$//' \
    | uniq \
    | wc -l
)

echo "Distinct dependencies: $count_ignore_version (with all versions: $count_all)"
echo "See $outfile_tree for tree list or $outfile_flat for flat dependencies list only"

echo
echo "Listing jackson dependencies:"
cat "$outfile_flat" | grep com.fasterxml.jackson | sed 's/^/- /'

echo
echo "Listing available updates:"
echo

versions() {
  target=$1

  tmp=$(mktemp)
  mvn -q \
    $target \
    -Dversions.outputFile="$tmp" \
    -Dmaven.version.rules="file:///$dir/versions-rules.xml"

  cat "$tmp" | sed 's/^/  /'
  rm "$tmp"
}

versions versions:display-dependency-updates
versions versions:display-plugin-updates
