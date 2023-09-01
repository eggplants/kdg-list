# kanji-de-go-list

Make problem lists of kanji-de-go!

[![Update]](https://github.com/eggplants/kanji-de-go-list/actions/workflows/update.yml)
[![Website]](https://kanji-de-go-list.onrender.com)

[Update]: <https://github.com/eggplants/kanji-de-go-list/actions/workflows/update.yml/badge.svg>
[Website]: <https://img.shields.io/website?label=kanji-de-go-list.onrender.com&url=https%3A%2F%2Fkanji-de-go-list.onrender.com>

## Requirements

- awk
- imagemagick
- jq
- ruby

## Generate lists

1. `mkdir kanji && cd kanji`
1. Download `漢字でGO!.zip` from <https://plicy.net/GamePlay/155561>
1. Extract to `漢字でGO!`
1. Run `./gen.sh`
