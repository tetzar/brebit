# General Tips

- エミュレーターがリストに表示されない時:
  - `~/Library/Android/sdk/emulator/emulator -list-avds` でデバイスを確認し `~/Library/Android/sdk/emulator/emulator -avd Pixel_3a_API_33_arm64-v8a` で起動する

# iOS Tips

- `flutter doctor`, `flutter buid ios`で様子を見る
- とりあえず`open ~/Applications/JetBrains\ Toolbox/Android\ Studio.app`する。ターミナルから開くだけとかいう嘘みたいな方法だが**本当に効果がある**
- `flutter clean`, `rm -rf ~/Library/Developer/Xcode/DerivedData/`でキャッシュ削除
- `~/.pub-cache` を消して `pub get`
- Rosetta を使用してターミナルを開く

## Cocoapods

- 任意の `Ruby` を参照できていてもシステムの `cocoapods` を参照してしまうことなどがあるある
- あと `Homebrew` で入れた `cocoapods` を参照していることもある
- @Harxxki のおすすめ: `asdf` の `Ruby` を入れて `gem install cocoapods`
  - `asdf` で一括管理できる
  - `rbenv` の `Ruby` や `rbenv`, `Homebrew` の `cocoapods` は破壊しろ
  - `asdf` の `Ruby` のパスが `/usr/local/bin/pod` の前に来るように注意 

pod install が通らないときは `cd ios`,

- `pod repo update`
- `rm -rf Podfile.lock`

# Other

- [振り返ったらFlutterでのアプリ開発のTipsが溜まっているスクラップ](https://zenn.dev/sgr_ksmt/scraps/f2437c38594ba1)
