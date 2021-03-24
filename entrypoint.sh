#!/bin/sh

set -e

# extract info
version=${GITHUB_REF}
version=${version#refs/tags/}
version=${version#v}


name=$(yq -r .final_name config/final.yml)
if [ "${name}" = "null" ]; then
  name=$(yq -r .name config/final.yml)
fi

remote_repo="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

# configure git
git config --global user.name "actions/bosh-releaser@v1"
git config --global user.email "<>"


if [ ! -z "${INPUT_BUNDLE}" ] && [ "${INPUT_BUNDLE}" != "false" ]; then
  echo "installing bundle: ${INPUT_BUNDLE}"
  apk add ruby
  gem install bundler -v "${INPUT_BUNDLE}"
fi


# remove existing release if any
if [ -f releases/${name}/${name}-${version}.yml ]; then
  echo "removing pre-existing version ${version}"
  yq -r -y "{ \"builds\": (.builds | with_entries(select(.value.version != \"${version}\"))), \"format-version\": .[\"format-version\"]}" < releases/${name}/index.yml > tmp
  mv tmp releases/${name}/index.yml
  rm -f releases/${name}/${name}-${version}.yml
  git commit -a -m "reset release ${version}"
fi

echo "creating bosh release: ${name}-${version}.tgz"
cat - > config/private.yml <<EOS
---
blobstore:
  options:
    access_key_id: ${AWS_BOSH_ACCES_KEY_ID}
    secret_access_key: ${AWS_BOSH_SECRET_ACCES_KEY}
EOS
bosh create-release --force --final --version=${version} --tarball=${name}-${version}.tgz

echo "pushing changes to git repository"
git add releases/${name}/${name}-${version}.yml
git commit -a -m "cutting release ${version}"
git push ${remote_repo} HEAD:${INPUT_TARGET_BRANCH}

# make asset readble outside docker image
chmod 644 ${name}-${version}.tgz
echo "::set-output name=file::${name}-${version}.tgz"
echo "::set-output name=version::${version}"

