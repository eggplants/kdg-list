#!/usr/bin/env bash

set -euxo pipefail

curl -s `https://raw.githubusercontent.com/Formidi/KanzideGoFAQ/gh-pages/md/faq.md` > game_page
page_version="$(
  grep -oEm1 'Win\([^)]+' game_page | sed 's/....//'
)"
[[ -z "$page_version" ]] && exit 1
if git ls-remote --tags origin|awk '$0=$2'|sed 's;^refs/tags/;;' |
   sed 's/.*/@&@/' | grep -q "@${page_version}@"
then
  exit 0
fi

file_id="$(
  curl -s "$(
    < game_page grep -oEm1 'https://drive.google.com/drive/folders/[^<]+'
  )" |
  grep -oE '<div data-id="'".*"'" data-target="doc" draggable="true"' |
  awk -F'"' '$0=$2'
)"
[[ -z "$file_id" ]] && exit 1

git clone --depth 1 "https://gist.github.com/eggplants/f638ba6a6208e4e37f49ccae94cc948e" _
mv _/google-drive-downloader.sh .
rm -rf _
chmod +x google-drive-downloader.sh
./google-drive-downloader.sh "$file_id" '漢字でGO!.zip'
unzip -Ocp932 '漢字でGO!.zip'
rm '漢字でGO!.zip' google-drive-downloader.sh game_page

dl_version="$(./check_version.sh)"
[[ -z "$dl_version" ]] && exit 0
if git ls-remote --tags origin|awk '$0=$2'|sed 's;^refs/tags/;;' |
   sed 's/.*/@&@/' | grep -q "@${dl_version}@"
then
  exit 1
fi

./gen.sh
if [[ -z "$(git status -s)" ]]
then
  exit 0
fi

git config user.name  "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add .
git commit -m "update ${dl_version} - $(date +%Y-%m-%d)"
git tag "$dl_version"
git push
git push --tags
