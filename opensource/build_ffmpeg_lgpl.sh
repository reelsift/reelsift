#!/bin/bash
# LGPL 版の ffmpeg / ffprobe を、Apple シリコンと Intel の両方で動く形(ユニバーサル)で作るスクリプト。
# GPL の部品(x264 など)は入れない。変換には Mac 標準の VideoToolbox を使う。
# AV1 の動画を読むために dav1d(BSD ライセンス。LGPL・App Store と両立する)を組み込む。
#
# 使い方(ターミナルで、AppStore フォルダがある場所から):
#   xcode-select --install                    # 初回だけ(コンパイラ)
#   brew install nasm pkg-config meson ninja  # 初回だけ
#   bash AppStore/build_ffmpeg_lgpl.sh
# 出来上がり: ./ffmpeg-lgpl/ffmpeg と ./ffmpeg-lgpl/ffprobe
# 配布するときは、使ったバージョンのソース(ダウンロードした tar.xz)を入手できるようにしておくこと(LGPL の条件)。
set -euo pipefail

VERSION="${FFMPEG_VERSION:-7.1}"
DAV1D_VERSION="${DAV1D_VERSION:-1.4.3}"
# 作業場所は、名前に空白のない所にする(「x 4」のように空白があると、dav1d が見つからなくなるため)
WORK="${FFMPEG_WORK:-$HOME/reelsift-ffmpeg-build}"
case "$WORK" in *" "*) echo "作業場所の名前に空白があります: $WORK"; exit 1;; esac
OUT="$(pwd)/ffmpeg-lgpl"
mkdir -p "$WORK" "$OUT"
cd "$WORK"

for tool in nasm pkg-config meson ninja; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "「$tool」が見つかりません。先に次を実行してください: brew install nasm pkg-config meson ninja"
    exit 1
  fi
done

if [ ! -f "ffmpeg-$VERSION.tar.xz" ]; then
  curl -LO "https://ffmpeg.org/releases/ffmpeg-$VERSION.tar.xz"
fi
if [ ! -f "dav1d-$DAV1D_VERSION.tar.gz" ]; then
  curl -L -o "dav1d-$DAV1D_VERSION.tar.gz" \
    "https://code.videolan.org/videolan/dav1d/-/archive/$DAV1D_VERSION/dav1d-$DAV1D_VERSION.tar.gz"
fi

COMMON_FLAGS=(
  --disable-gpl --disable-nonfree          # LGPL のまま(ここが大切)
  --enable-videotoolbox --enable-audiotoolbox
  --enable-libdav1d                        # AV1 をソフトで読む(BSD ライセンス)
  --disable-ffplay --disable-doc --disable-network
  --disable-debug --enable-small
  --disable-sdl2 --disable-securetransport --disable-xlib --disable-libxcb
)

for ARCH in arm64 x86_64; do
  if [ "$ARCH" = "arm64" ]; then FAMILY=aarch64; else FAMILY=x86_64; fi

  # --- dav1d(静的ライブラリとして作り、ffmpeg に組み込む) ---
  rm -rf "dav1d-src-$ARCH" "dav1d-$ARCH"
  mkdir "dav1d-src-$ARCH"
  tar xf "dav1d-$DAV1D_VERSION.tar.gz" -C "dav1d-src-$ARCH" --strip-components=1
  cat > "cross-$ARCH.txt" <<CROSS
[binaries]
c = ['clang', '-arch', '$ARCH']
ar = 'ar'
strip = 'strip'
nasm = 'nasm'

[host_machine]
system = 'darwin'
cpu_family = '$FAMILY'
cpu = '$ARCH'
endian = 'little'

[built-in options]
c_args = ['-mmacosx-version-min=13.0']
c_link_args = ['-mmacosx-version-min=13.0']
CROSS
  meson setup "dav1d-src-$ARCH/build" "dav1d-src-$ARCH" \
    --cross-file "cross-$ARCH.txt" \
    --default-library=static --buildtype=release \
    -Denable_tools=false -Denable_tests=false \
    --prefix="$WORK/dav1d-$ARCH" --libdir=lib
  ninja -C "dav1d-src-$ARCH/build" install

  # --- ffmpeg ---
  rm -rf "src-$ARCH" "install-$ARCH"
  mkdir "src-$ARCH"
  tar xf "ffmpeg-$VERSION.tar.xz" -C "src-$ARCH" --strip-components=1
  pushd "src-$ARCH" >/dev/null
  PKG_CONFIG_PATH="$WORK/dav1d-$ARCH/lib/pkgconfig" ./configure "${COMMON_FLAGS[@]}" \
    --arch="$ARCH" --target-os=darwin --enable-cross-compile \
    --cc="clang -arch $ARCH" \
    --pkg-config=pkg-config --pkg-config-flags=--static \
    --extra-cflags="-mmacosx-version-min=13.0" \
    --extra-ldflags="-mmacosx-version-min=13.0" \
    --prefix="$WORK/install-$ARCH"
  make -j"$(sysctl -n hw.ncpu)"
  make install
  popd >/dev/null
done

for BIN in ffmpeg ffprobe; do
  lipo -create "$WORK/install-arm64/bin/$BIN" "$WORK/install-x86_64/bin/$BIN" -output "$OUT/$BIN"
done

echo "完了: $OUT/ffmpeg と $OUT/ffprobe"
"$OUT/ffmpeg" -hide_banner -buildconf | grep -E "enable-gpl|disable-gpl|libdav1d" || true
echo "↑ 「--disable-gpl」と「--enable-libdav1d」があり、「--enable-gpl」が無いことを確認してください。"
"$OUT/ffmpeg" -hide_banner -decoders 2>/dev/null | grep -i dav1d || echo "※ dav1d が入っていません(AV1 は読めません)"
