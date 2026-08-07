#!/usr/bin/env bash

set -euxo pipefail

for _cmd in gdown git; do
  if ! command -v "$_cmd" &>/dev/null; then
    echo "Install: $_cmd" >&2
    exit 1
  fi
done

NAME="$(base64 -d <<<'5ryi5a2X44GnR08hCg==')"

curl -sL "$(
  curl -s 'https://raw.githubusercontent.com/Formidi/KanzideGoFAQ/gh-pages/md/faq.md' |
  grep -oEm1 'https://drive.google.com/drive/folders/[^<"]+'
)" > drive_page

# data-id is on <tr> elements, not <div>; exclude the "_gd" sentinel value
game_file_id="$(
  grep -oP '(?<=data-id=")[^"]+' drive_page |
  grep -v '^_' |
  tail -1
)"
rm drive_page
if [[ -z "$game_file_id" ]]; then
  exit 1
fi

if ! [[ -d "$NAME" ]]; then
  gdown "$game_file_id" -O game.zip
  unzip -q -Ocp932 game.zip
  rm game.zip
fi

# Version no longer embedded in the Drive filename; read it from the game data instead
game_version="$(grep -oP '(?<=")\d+\.\d+\.\d+\.[0-9a-zA-Z]+(?=\\")' "${NAME}/www/data/Map003.json" | head -1)"
if [[ -z "$game_version" ]]; then
  exit 1
fi

git pull --tags
if git tag -l | grep -q '^'"${game_version}"'$'; then
  exit 0
fi

./gen.sh "${game_version}"

if [[ -z "$(git status -s)" ]]; then
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
git rm --cached -r .
git add docs/
git commit -m "update ${game_version} / $(date +%Y-%m-%d)" --quiet || :
git push origin gh-pages -f

git checkout master
