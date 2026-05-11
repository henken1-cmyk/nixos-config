# usdb-import: turn a USDB-exported .txt into a ready-to-play USDX song folder.
# Parses #VIDEO:v=<id>,co=<url>,bg=<url|file>, downloads media, rewrites tags,
# moves everything under $USDX_SONGS_DIR/<Artist> - <Title>/.
#
# Wrapped by writeShellApplication — shebang and strict mode injected.

SONGS_DIR="${USDX_SONGS_DIR:-/games/usdx/songs}"

usage() {
  cat <<EOF
usage: usdb-import [TXT_FILE...]

With no args, processes ~/Downloads/*.txt.
Env: USDX_SONGS_DIR (default: /games/usdx/songs)
EOF
}

get_tag() {
  # $1 = file, $2 = tag name (without #)
  awk -v t="#${2}:" 'index($0, t) == 1 { sub(t, ""); print; exit }' "$1"
}

parse_video_meta() {
  local raw="$1"
  V_ID=""; V_CO=""; V_BG=""
  local IFS=','
  read -ra parts <<< "$raw"
  for p in "${parts[@]}"; do
    case "$p" in
      v=*)  V_ID="${p#v=}" ;;
      co=*) V_CO="${p#co=}" ;;
      bg=*) V_BG="${p#bg=}" ;;
    esac
  done
}

sanitize() {
  # Replace path-breaking chars for dir/file names
  printf '%s\n' "$1" | tr '/:' '__'
}

import_one() {
  local src="$1"
  local artist title video_raw
  artist=$(get_tag "$src" ARTIST)
  title=$(get_tag "$src" TITLE)
  video_raw=$(get_tag "$src" VIDEO)

  if [[ -z "$artist" || -z "$title" ]]; then
    echo "skip: $src — missing #ARTIST/#TITLE" >&2
    return 1
  fi

  local base
  base="$(sanitize "${artist} - ${title}")"
  local dst="${SONGS_DIR}/${base}"
  mkdir -p "$dst"
  echo "==> ${base}"

  local V_ID V_CO V_BG
  parse_video_meta "$video_raw"

  local video_file="${dst}/${base}.mp4"
  local mp3_file="${dst}/${base}.mp3"
  local cover_file="${dst}/${base} [CO].jpg"
  local bg_file="${dst}/${base} [BG].jpg"

  if [[ -n "$V_ID" && ( ! -f "$video_file" || ! -f "$mp3_file" ) ]]; then
    echo "  download video+mp3: $V_ID"
    ( cd "$dst" && yt-dlp \
        -f 'bv*[ext=mp4][height<=720]+ba[ext=m4a]/b[ext=mp4][height<=720]/b' \
        --merge-output-format mp4 \
        --extract-audio --keep-video --audio-format mp3 --audio-quality 2 \
        --no-progress \
        -o "${base}.%(ext)s" \
        "https://www.youtube.com/watch?v=${V_ID}" )
    find "$dst" -maxdepth 1 -type f \
      \( -name "*.f[0-9]*.mp4" -o -name "*.f[0-9]*.m4a" -o -name "*.f[0-9]*.webm" \
         -o -name "*.part" -o -name "*.ytdl" \) -delete
  elif [[ -z "$V_ID" ]]; then
    echo "  skip video: no v= id in #VIDEO tag"
  else
    echo "  video+mp3 already present"
  fi

  if [[ -n "$V_CO" && "$V_CO" =~ ^https?:// && ! -f "$cover_file" ]]; then
    echo "  download cover"
    curl -fsSL -o "$cover_file" "$V_CO" || echo "  cover download failed" >&2
  fi

  if [[ -n "$V_BG" && "$V_BG" =~ ^https?:// && ! -f "$bg_file" ]]; then
    echo "  download background"
    curl -fsSL -o "$bg_file" "$V_BG" || echo "  background download failed" >&2
  fi

  local dst_txt="${dst}/${base}.txt"
  local has_co has_bg
  has_co=""; [[ -f "$cover_file" ]] && has_co=1
  has_bg=""; [[ -f "$bg_file"    ]] && has_bg=1

  awk -v base="$base" -v has_co="$has_co" -v has_bg="$has_bg" '
    /^#(VIDEO|COVER|BACKGROUND):/ { next }
    /^#MP3:/ {
      print
      print "#VIDEO:" base ".mp4"
      if (has_co != "") print "#COVER:" base " [CO].jpg"
      if (has_bg != "") print "#BACKGROUND:" base " [BG].jpg"
      next
    }
    { print }
  ' "$src" > "${dst_txt}.tmp"
  mv "${dst_txt}.tmp" "$dst_txt"

  if [[ "$(realpath "$src")" != "$(realpath "$dst_txt")" ]]; then
    rm -f "$src"
  fi

  echo "  ok: $dst"
}

main() {
  local files=("$@")
  if [[ ${#files[@]} -eq 0 ]]; then
    shopt -s nullglob
    files=("$HOME"/Downloads/*.txt)
    shopt -u nullglob
  fi

  if [[ ${#files[@]} -eq 0 ]]; then
    usage
    exit 1
  fi

  mkdir -p "$SONGS_DIR"

  local failed=0
  for f in "${files[@]}"; do
    if [[ ! -f "$f" ]]; then
      echo "skip: $f not a file" >&2
      continue
    fi
    if ! grep -q '^#ARTIST:' "$f" || ! grep -q '^#TITLE:' "$f"; then
      echo "skip: $f (not a USDX txt)" >&2
      continue
    fi
    import_one "$f" || failed=$((failed + 1))
  done

  if (( failed > 0 )); then
    echo "$failed failed" >&2
    exit 1
  fi
}

main "$@"
