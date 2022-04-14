# Brebit

**An awesome breaking habit application.**

## Usage

### 0. 準備

1. flutter をインストール
2. Backend を起動: `https://github.com/tetzar/laradoc-rep`

### 1. API の URL を設定

`lib/network/api.dart` で`_url`を適切なやつに変える

### 2. Dependencies を取得する

```bash
flutter pub get
```

### 3. App を起動する

```bash
flutter run
```

## iOS Tips

- `flutter doctor`, `flutter buid ios`で様子を見る
- とりあえず`open ~/Applications/JetBrains\ Toolbox/Android\ Studio.app`する。ターミナルから開くだけとかいう嘘みたいな方法だが**本当に効果がある**
- `flutter clean`, `rm -rf ~/Library/Developer/Xcode/DerivedData/`でキャッシュ削除

### Cocoapods

- Ruby Version を上げて CocoaPods を再 install
- Ruby を rbenv で管理して gem が rbenv の管理下に置かれているのを確認してから`gem install cocoapods`
- RubyGems で pod を入れるとうまく動かない時がある (`Warning: CocoaPods is installed but broken. Skipping pod install.`)
  - ので、`brew install cocoapods` && `brew link --overwrite cocoapods`

pod install が通らないときは `cd ios`,
- `pod repo update`
- `rm -rf Podfile.lock`