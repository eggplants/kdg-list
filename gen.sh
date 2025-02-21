#!/usr/bin/env bash

set -euo pipefail

GAME_VERSION="$1"

LOG="${LOG:-}"
[[ -n "$LOG" ]] && echo Verbose LOG will not be printed.

SKIP="${SKIP:-}"
[[ -n "$SKIP" ]] && echo Processes of image conversion will be skipped.

if ! command -v awk magick resizer
then
  echo "install: awk magick resizer" >&2
  exit 1
fi

if ! [[ -d '漢字でGO!' ]]
then
  echo "Download & Extract: <https://plicy.net/GamePlay/155561>" >&2
  exit 1
fi

echo "[TSV]"

cat<<'A' > _answer.tsv
Lv00_0001	よ	-
Lv00_0002	もみじ	-
A
grep -E '^(問題|解１|文上|文下):' 漢字でGO\!/www/img/battlebacks2/Lv*.xcf |
cut -d: -f2- |
tr -d \\r' ' |
sed -r 's/₨|.I\[[0-9]+\]//g' |
sed -zr 's/文上:([^\n]+)\n文下:/\1/g' |
xargs -n3 |
sed -r 's/(問題|解１|文上)://g' |
tr ' ' \\t >> _answer.tsv

find '漢字でGO!/www/img/pictures' -name 'Lv*' |
  grep -E 'Lv[0-9]+_[0-9]+.rpgmvp' |
  grep -v 0000 |
  awk -F/ '$0=$NF' | sort -V > _problem_a.tsv

find '漢字でGO!/www/img/pictures' -name 'LvCa004_*' |
  awk -F/ '$0=$NF' | sort -V > _problem_b.tsv

len_a="$(wc -l <_answer.tsv)"
len_b="$(wc -l <_problem_a.tsv)"
len_c="$(wc -l <_problem_b.tsv)"
echo "_answer.tsv lines: <${len_a}>"
echo "_problem_a.tsv:    <${len_b}>"
echo "_problem_b.tsv:    <${len_c}>"
if ! [[ "$len_a" == "$((len_b+len_c))" ]]
then
  echo "Error: _answer.tsv lines <${len_a}> != _problem_a.tsv <${len_b}>  + _problem_b.tsv <${len_c}> mismatch.">&2
  exit 1
fi

sed $'1iproblem\tanswer\tdescription' _answer.tsv > kdg.tsv

mkdir -p ./kanji_problems/png
mkdir -p ./kanji_problems/webp

if [[ -z "$SKIP" ]]; then
  echo "[Convert RPGMVP images of problems into PNG]"

  find '漢字でGO!/www/img/pictures' |
  grep -E "Lv(Ca)?[0-9]+_[0-9]+.rpgmvp" |
  grep -v '_0000.png' |
  while read -r i
  do
    [[ -n "$LOG" ]] && printf '\e[K\r%s' "$i"
    dest_name='./kanji_problems/png/'"$(basename "$i" | sed 's/rpgmvp/png/')"
    printf '\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52' > "$dest_name"
    tail -c +33 "$i" >> "$dest_name"
  done
  [[ -n "$LOG" ]] && echo

  echo "[Shrink PNG]"
  find kanji_problems/png -name 'Lv*.png' -print0 | xargs -0 -P0 -I{} -n1 resizer -o -h 200 {} {}

  echo "[PNG -> WEBP]"
  if [[ -n "$LOG" ]]
  then
    magick mogrify -monitor -path kanji_problems/webp -format webp kanji_problems/png/*.png
  else
    magick mogrify -path kanji_problems/webp -format webp kanji_problems/png/*.png
  fi
fi

echo "[HTML:problem lists]"

levels=()
while read -r i
do
  levels+=("$i")
done < <(
  find kanji_problems/png -type f -name '*' |
  awk -F'[_/]' '$0=$(NF-1)' |
  sort -V | uniq
)

levels_len="${#levels[@]}"
for (( idx=0; idx<levels_len; idx++ ))
do
  level="${levels[idx]}"
  f="kdg_list_${level}.html"
  count="$(find kanji_problems/png -name "$level"'_*.png' | wc -l)"

  if [[ "$idx" != 0 ]]
  then
    prv="<span><a href='kdg_list_${levels[idx-1]}.html'>${levels[idx-1]}</a></span>"
  else
    prv=""
  fi
  if [[ "$((idx+1))" != "$levels_len" ]]
  then
    nxt="<span><a href='kdg_list_${levels[idx+1]}.html'>${levels[idx+1]}</a></span>"
  else
    nxt=""
  fi

  echo "${level} -> ${f}, ${count} problem(s)"
  { sed 's/^ *//' << EOS;} > "$f"
  <!DOCTYPE html>
  <html lang="ja" dir="ltr">
  <head>
  <meta charset="UTF-8">
  <title>${f//.*/}</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  </head>
  <body>
  <h1>${level} -- 全${count}問</h1>
  ＜＜${prv:-}｜<a href='index.html'>●</a>｜${nxt:-}＞＞
  <table border=1>
  <thead>
  <tr>
  <th>ID</th>
  <th>問題</th>
  <th>答え</th>
  <th>解説</th>
  </tr>
  </thead>
  <tbody>
EOS

  grep "$level" kdg.tsv | while IFS=$'\t' read -r a b c
  do
    cat<<EOS
    <tr>
    <td>${a}</td>
    <td><a href='kanji_problems/png/${a}.png'><img alt='${a}' width=200 height=57 loading='lazy' src='kanji_problems/webp/${a}.webp'></a></td>
    <td>${b}</td>
    <td>${c}</td>
    </tr>
EOS
  done | sed 's/^ *//' >> "$f"

  sed 's/^ *//' <<'EOS'>> "$f"
  </tbody>
  </table>
  </body>
  </html>
EOS

done

echo "[HTML:index]"
cat << EOS > index.html
<!DOCTYPE html>
<html lang="ja" dir="ltr">
<head>
<meta charset="UTF-8">
<title>kdg_list</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
</head>
<body>
<h1><a href="https://plicy.net/GamePlay/155561">漢字でGO!</a>　非公式レベル別問題リスト</h1>

<h2>概要</h2>

<p>このサイトは漢字でGO!の問題と答えをレベル別にリストアップし、対策するための非公式サイトです。</p>
<p>問題画像・答え・解説テキストの権利はすべて製作者さまに帰属します。</p>
<p>最終更新日：$(LANG=C date +%Y-%m-%d) / ${GAME_VERSION}</p>

<h2>リスト一覧</h2>

<ol>
  <li><a href='kdg_list_Lv00.html'>Lv00 -- サンプル</a></li>
  <li><a href='kdg_list_Lv01.html'>Lv01 -- 漢検10〜5級</a></li>
  <li><a href='kdg_list_Lv02.html'>Lv02 -- 漢検6〜準2級</a></li>
  <li><a href='kdg_list_Lv03.html'>Lv03 -- 漢検4〜準1級</a></li>
  <li><a href='kdg_list_Lv04.html'>Lv04 -- 漢検2〜1級</a></li>
  <li><a href='kdg_list_Lv05.html'>Lv05 -- 漢検準1級〜対象外</a></li>
  <li><a href='kdg_list_Lv06.html'>Lv06 -- 対象外</a></li>
  <li><a href='kdg_list_Lv07.html'>Lv07 -- 対象外</a></li>
  <li><a href='kdg_list_LvCa004.html'>LvCa004 -- JLPT N5</a></li>
</ol>

<h2>レベルと漢検の対応</h2>

<blockquote class="twitter-tweet">
<p lang="ja" dir="ltr">
【難易度の範囲について】<br>
（以下は紹介動画で使用した画像）出題される問題は大まかに漢検を基準としております。<br>
但し、配当漢字でも読みが簡単と判断したものはひとつ下のレベルに下げていたり、難しい問題はレベルを上げている場合がございます。
<a href="https://t.co/K2ds85cO41">pic.twitter.com/K2ds85cO41</a>
</p>
&mdash; 『漢字でGO!』開発 (@KanzideGo)
<a href="https://twitter.com/KanzideGo/status/1691044777972944896?ref_src=twsrc%5Etfw">August 14, 2023</a>
</blockquote>

</body>
</html>
EOS

mkdir -p docs/
if [[ -d  docs/kanji_problems ]]
then
  rm -rf docs/kanji_problems
fi
mv kanji_problems index.html kdg_list_Lv*.html docs

echo "[DONE!]"
