#!/bin/bash

echo "== Validating sites.yml =="
# Validate and lint the YAML.
yamllint -d relaxed sites.yml || exit 3
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

echo "== Generating legacy pages ==" &&
python generate-legacy-pages.py &&

if [ "$TRAVIS_SECURE_ENV_VARS" = true \
	-a "$TRAVIS_PULL_REQUEST" = false \
	-a "$TRAVIS_BRANCH" = master ]
then
	echo "== Validating updater URLs ==" &&
	cram tests &&

	echo "== Configuring environment ==" &&

	# Configure SSH. The file .travis/ssh-rsa-key.enc must contain
	# an encrypted private RSA key for communicating with the git remote.
	mkdir -p "$HOME/.ssh" &&
	openssl aes-256-cbc \
		-K "$encrypted_4fc273333c82_key" \
		-iv "$encrypted_4fc273333c82_iv" \
		-in '.travis/ssh-rsa-key.enc' \
		-out "$HOME/.ssh/id_rsa" -d &&
	chmod 400 "$HOME/.ssh/id_rsa" &&

	# Configure git settings.
	git config --global user.email "travis@travis-ci.com" &&
	git config --global user.name "Travis CI" &&

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
		git commit -m "Update list of update sites (Travis build $TRAVIS_BUILD_NUMBER)" &&
		git pull --rebase &&
		git push -q origin gh-pages > /dev/null || exit 2
	else
		echo "No changes to generated files detected; skipping git commit."
	fi

	echo "Update complete."
else
	echo "Skipping non-canonical branch $TRAVIS_BRANCH"
fi
