# iOS Tips

- `flutter doctor`, `flutter buid ios`で様子を見る
- とりあえず`open ~/Applications/JetBrains\ Toolbox/Android\ Studio.app`する。ターミナルから開くだけとかいう嘘みたいな方法だが**本当に効果がある**
- `flutter clean`, `rm -rf ~/Library/Developer/Xcode/DerivedData/`でキャッシュ削除
- `~/.pub-cache` を消して `pub get`

## Cocoapods

- Ruby Version を上げて CocoaPods を再 install
- Ruby を rbenv で管理して gem が rbenv の管理下に置かれているのを確認してから`gem install cocoapods`
- RubyGems で pod を入れるとうまく動かない時がある (`Warning: CocoaPods is installed but broken. Skipping pod install.`)
  - ので、`brew install cocoapods` && `brew link --overwrite cocoapods`

pod install が通らないときは `cd ios`,
- `pod repo update`
- `rm -rf Podfile.lock`
