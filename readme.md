## 概要

Neovimを [GhostText](https://github.com/fregante/GhostText) のエディタ側として使うためのプラグイン

## 特徴

Pythonなどの外部に依存せず、Neovimの機能のみを使う。通信部分には `socket.nvim` を使っている。

## 依存パッケージ

- https://github.com/stg73/socket.nvim (WebSocketとHTTP)
- https://github.com/stg73/modules.nvim (socket.nvim が依存 SHA1など)

## 使い方

次のLuaを実行するとブラウザから利用できる状態になる:
```lua
require("ghosttext").start()
```
詳細は [help](doc/ghosttext.jax) を参照。
