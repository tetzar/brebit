# Brebit

**An awesome HABIT-BREAKING APPLICATION.**

## Usage (Development Environments)

### 0. 準備

1. flutter をインストール
2. Backend を起動: `https://github.com/tetzar/laradoc-rep`

### 1. API の URL を設定

`lib/api/api.dart` で`_url`を適切なものに変える

### 2. Dependencies を取得する

```bash
flutter pub get
```

### 3. App を起動する

```bash
flutter run
```

## Usage (Production Environments)

### 1. Dependencies を取得する

```bash
flutter pub get
```

### 2. App を起動する

```bash
flutter run
```

## Architecture

```
Firebase
   ▲
   │
認証情報
   │
   ▼
Brebit App ◄─── Data, Image ───► Heroku (as data storage)
     ▲ │                          │
     │ │                          │
Image│ │Request              Image│
     │ │                          │
     │ ▼                          │
AWS (as image storage) ◄──────────┘
```

