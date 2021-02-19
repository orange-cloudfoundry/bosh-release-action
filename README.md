#  Bosh release action

Github action to generate a new version of bosh final release

## Inputs

### `target_branch`

The name of the branch where genereated release files sould be pushed. Default `"master"`.

## Outputs

### `file`

Name of the generated release.

## Example usage

```
uses: orange-cloudfoundry/bosh-release-action@v1
with:
  target_branch: master
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  AWS_BOSH_ACCES_KEY_ID: ${{ secrets.AWS_BOSH_ACCES_KEY_ID }}
  AWS_BOSH_SECRET_ACCES_KEY: ${{ secrets.AWS_BOSH_SECRET_ACCES_KEY }}
```
