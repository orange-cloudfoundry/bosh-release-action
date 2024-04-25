#!/bin/sh

set -e

# extract info
case "${GITHUB_REF:?required}" in
refs/tags/*)
  version=${GITHUB_REF#refs/tags/}
  version=${version#v}
  release=true
  ;;
refs/heads/*)
  version=${GITHUB_REF#refs/heads/}
  release=false
  ;;
refs/pull/*)
  pull_number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
  version=pr-${pull_number}
  release=false
  ;;
esac

name=$(yq -r .final_name config/final.yml)
if [ "${name}" = null ]; then
  name=$(yq -r .name config/final.yml)
fi

remote_repo="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@${GITHUB_SERVER_URL#https://}/${GITHUB_REPOSITORY}.git"

# configure git
git config --global user.name "actions/bosh-releaser@v7"
git config --global user.email "<>"
git config --global --add safe.directory /github/workspace

if [ -n "${INPUT_BUNDLE}" ] && [ "${INPUT_BUNDLE}" != false ]; then
  echo "installing bundle: ${INPUT_BUNDLE}"
  apk add ruby
  gem install bundler -v "${INPUT_BUNDLE}"
fi

if [ "${release}" = true ]; then
  # remove existing release if any
  if [ -f "releases/${name}/${name}-${version}.yml" ]; then
    echo "removing pre-existing version ${version}"
    yq -r -y "{ \"builds\": (.builds | with_entries(select(.value.version != \"${version}\"))), \"format-version\": .[\"format-version\"]}" < "releases/${name}/index.yml" > tmp
    mv tmp "releases/${name}/index.yml"
    rm -f "releases/${name}/${name}-${version}.yml"
    git commit -a -m "reset release ${version}"
  fi
fi

if [ -n "${AWS_BOSH_ACCES_KEY_ID}" ]; then
  cat - > config/private.yml <<EOS
---
blobstore:
  options:
    access_key_id: ${AWS_BOSH_ACCES_KEY_ID}
    secret_access_key: ${AWS_BOSH_SECRET_ACCES_KEY}
EOS
else
  echo "::warning::AWS_BOSH_ACCES_KEY_ID not set, skipping config/private.yml"
fi

echo "creating bosh release: ${name}-${version}.tgz"
if [ "${release}" = true ]; then
  bosh create-release --force --final --version="${version}" --tarball="${name}-${version}.tgz"
else
  bosh create-release --force --timestamp-version --tarball="${name}-${version}.tgz"
fi

if [ "${release}" = true ]; then
  echo "pushing changes to git repository"
  git add .final_builds
  git add "releases/${name}/index.yml"
  git add "releases/${name}/${name}-${version}.yml"
  git commit -a -m "cutting release ${version}"
  git push "${remote_repo}" "HEAD:${INPUT_TARGET_BRANCH}"
fi

# make asset readble outside docker image
chmod 0644 "${name}-${version}.tgz"
>>"${GITHUB_OUTPUT}" echo "file=${name}-${version}.tgz"
>>"${GITHUB_OUTPUT}" echo "version=${version}"

