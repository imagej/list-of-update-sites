#!/bin/bash

"$(dirname "$0")/lint.sh" || exit $?

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
