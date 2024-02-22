#!/bin/bash

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
git grep name: sites.yml |
	grep -A999999 'name: "[0-9]' |
	sed 's;.*name: "\([^"]*\)"$;\1;' >actual
cat actual | LC_ALL=C sort --ignore-case >expected
if diff actual expected
then
	echo "Update sites are ordered correctly."
else
	echo "Please list sites in alphabetical order!"
	exit 5
fi
echo "== Generating legacy pages ==" &&
python generate-legacy-pages.py &&

echo "== Validating updater URLs ==" &&
cram tests &&

# Stop here if this is not a build of the main branch.
if [ -z "$GITHUB_BUILD_NUMBER" ]; then
	echo "PR build complete."
	exit 0
fi &&

echo "== Configuring environment ==" &&

# Configure git settings.
git config --global user.email "ci@scijava.org" &&
git config --global user.name "GitHub Action" &&

echo "== Pushing generated pages ==" &&

# Clone the repository's gh-pages branch.
git clone --quiet --branch gh-pages --depth 1 git@github.com:imagej/list-of-update-sites > /dev/null &&

# Update the published files.
cd list-of-update-sites &&
mv -f ../sites.html index.html &&
mv -f ../*.[xy]ml . &&

# Commit and push the changes.
git add . &&
success=1

test "$success" || exit 1

if git diff --staged | grep '^[+-]' | grep -v '^[+-]\{3\}' | grep -v 'This page was last modified on'
then
	# There are changes besides just the timestamp.
	git commit -m "Update list of update sites (GitHub build $GITHUB_BUILD_NUMBER)" &&
	git pull --rebase &&
	git push -q origin gh-pages > /dev/null || exit 2
else
	echo "No changes to generated files detected; skipping git commit."
fi

echo "Update complete."
