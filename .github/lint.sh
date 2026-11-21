#!/bin/bash

# Lints sites.yml. Safe to run locally: ./.github/lint.sh

cd "$(dirname "$0")/.." || exit 1

command -v yamllint >/dev/null || {
	echo 'Please install yamllint (e.g.: uv tool install yamllint).'
	exit 2
}

echo "== Validating sites.yml =="
# Validate and lint the YAML.
yamllint -d relaxed -d "{rules: {key-duplicates: {}}}" sites.yml || exit 3
# Check for duplicate IDs.
duplicates=$(grep '^    id: ' sites.yml | sort | uniq -d)
if [ "$duplicates" ]
then
	echo "Duplicate site IDs:"
	echo "$duplicates"
	exit 4
else
	echo "No duplicate IDs."
fi
# Check that update sites are in sorted order.
tmpdir=$(mktemp -d) || exit 1
trap 'rm -rf "$tmpdir"' EXIT
grep name: sites.yml |
	grep -A999999 'name: "[0-9]' |
	sed 's;.*name: "\([^"]*\)"$;\1;' >"$tmpdir/actual"
LC_ALL=C sort --ignore-case "$tmpdir/actual" >"$tmpdir/expected"
if diff -q "$tmpdir/actual" "$tmpdir/expected" >/dev/null
then
	echo "Update sites are ordered correctly."
else
	echo "Please list sites in alphabetical order!"
	git diff --no-index "$tmpdir/actual" "$tmpdir/expected"
	exit 5
fi
