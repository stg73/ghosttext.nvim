## 概要

[GhostText](https://github.com/fregante/GhostText) のためのNeovimプラグイン

## 特徴

Pythonなどの外部に依存せず、Neovimの機能のみを使う。

## 依存

通信には、 `luv` を使う `socket.nvim` を使っている。そのため、以下のプラグインに依存する:
- https://github.com/stg73/socket.nvim (通信)
- https://github.com/stg73/modules.nvim (socket.nvim が依存 SHA1など)

## 使い方

次のLuaを実行する:
```lua
require("ghosttext").start()
```
詳細は [vimdoc](doc/ghosttext.jax) を参照。
