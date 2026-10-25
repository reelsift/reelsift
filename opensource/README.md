# ReelSift — オープンソース / Open Source

ReelSift(Mac App Store)は、次のオープンソースソフトウェアを使っています。
ここに、使ったバージョンのソースコードと、作り方(ビルドの設定)を置いています。

ReelSift (Mac App Store) uses the open-source software listed below.
This page provides the source code of the exact versions used, and the build configuration.

| 部品 / Component | バージョン / Version | ライセンス / License | ソースコード / Source |
|---|---|---|---|
| FFmpeg(`ffmpeg`・`ffprobe`) | 7.1 | LGPL v2.1 以降(GPL の部品は含みません) | [ffmpeg-7.1.tar.xz](ffmpeg-7.1.tar.xz) |
| dav1d(AV1 の読み取り) | 1.4.3 | BSD 2-Clause | [dav1d-1.4.3.tar.gz](dav1d-1.4.3.tar.gz) |

## 日本語

### どう使っているか
- FFmpeg の `ffmpeg` と `ffprobe` は、ReelSift の本体に組み込まず、**別のプログラムとしてアプリの中に同梱**しています。mkv・webm・avi・wmv などの形式の読み取り、サムネイルの作成、変換しながらの再生、場面の範囲の書き出しに使います。
- dav1d は、FFmpeg に組み込んで、AV1 の動画を読むために使っています。
- FFmpeg・dav1d のソースコードは、**改変していません**(上の公式のソースのままです)。
- FFmpeg は、`--disable-gpl --disable-nonfree` で作った LGPL 版です。

### ビルドの設定
上の2つのソースコードを、次の設定で作っています。設定の全文は [BUILD-CONFIGURATION.txt](BUILD-CONFIGURATION.txt)、作るためのスクリプトは [build_ffmpeg_lgpl.sh](build_ffmpeg_lgpl.sh) です。

```
xcode-select --install                    # 初回だけ(コンパイラ)
brew install nasm pkg-config meson ninja  # 初回だけ
bash build_ffmpeg_lgpl.sh                 # ffmpeg / ffprobe(Apple シリコンと Intel のユニバーサル)ができます
```

### ライセンス
- FFmpeg のライセンスの全文は、ソースコードの中の `COPYING.LGPLv2.1` と `LICENSE.md` にあります。FFmpeg の法的な説明は https://ffmpeg.org/legal.html です。
- dav1d のライセンスの全文は、ソースコードの中の `COPYING` にあります。
- アプリの中でも、「☰ › このアプリについて・ライセンス」で確認できます。

## English

### How they are used
- `ffmpeg` and `ffprobe` from FFmpeg are bundled inside the app as **separate executables**, not linked into the ReelSift app itself. They are used to read formats such as mkv, webm, avi and wmv, to create thumbnails, to convert video for playback, and to export a selected range.
- dav1d is built into FFmpeg to read AV1 video.
- The FFmpeg and dav1d source code is **unmodified** (exactly the official releases above).
- FFmpeg is the LGPL build, configured with `--disable-gpl --disable-nonfree`.

### Build configuration
Both are built with the configuration in [BUILD-CONFIGURATION.txt](BUILD-CONFIGURATION.txt). The script that builds them is [build_ffmpeg_lgpl.sh](build_ffmpeg_lgpl.sh).

```
xcode-select --install                    # first time only (compiler)
brew install nasm pkg-config meson ninja  # first time only
bash build_ffmpeg_lgpl.sh                 # produces universal ffmpeg / ffprobe (Apple silicon + Intel)
```

### Licenses
- The full FFmpeg license texts are in the source code (`COPYING.LGPLv2.1` and `LICENSE.md`). FFmpeg's legal notes: https://ffmpeg.org/legal.html
- The full dav1d license text is in the source code (`COPYING`).
- They are also shown in the app under ☰ › About / Licenses.
