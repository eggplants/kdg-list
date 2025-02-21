#!/usr/bin/env bash

set -euxo pipefail

if ! command -v gdown git &>/dev/null; then
  echo 'Install: gdown, git' >&2
  exit 1
fi

curl -s "$(
  curl -s 'https://raw.githubusercontent.com/Formidi/KanzideGoFAQ/gh-pages/md/faq.md' |
  grep -oEm1 'https://drive.google.com/drive/folders/[^<"]+'
)" > drive_page

game_file_id="$(
  grep -oP '(?<=<div data-id=")[^"]+(?=")' drive_page |
  tail -1
)"
game_version="$(grep -oP '(?<=>漢字でGO!)[^<]+(?=.zip<)' drive_page | tail -1 | tr -d ' ')"
if [[ -z "$game_file_id" || -z "$game_version" ]]; then
  exit 1
fi
rm drive_page

git pull --tags
if git tag -l | grep -q '^'"${game_version}"'$'; then
  exit 0
fi

if ! [[ -d '漢字でGO!' ]]; then
  gdown "$game_file_id" -O game.zip
  unzip -q -Ocp932 game.zip
  if ! grep -q '"'"${game_version}"'\\"' '漢字でGO!/www/data/Map003.json'; then
    exit 1
  fi
  rm game.zip
fi

./gen.sh "${game_version}"

if [[ -z "$(git status -s)" ]]
then
  exit 0
fi

git config user.name  "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

git add kdg.tsv
git commit -m "update ${game_version} / $(date +%Y-%m-%d)"
git tag "$game_version"
git push
git push --tags

git branch -D gh-pages || :
git checkout --orphan gh-pages
git rm --cached -r .github .gitignore README.md ci.sh gen.sh
git add docs/
git commit -m "update ${game_version} / $(date +%Y-%m-%d)" --quiet || :
git push origin gh-pages -f

# return to master:
# git add .
# git checkout master
