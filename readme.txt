GhostText (https://github.com/fregante/GhostText) のためのNeovimプラグイン

他にも似たようなプラグインはあるが、それらとの違いは、Pythonなどの外部に依存せず、Neovimの機能のみ必要とすることである。
ブラウザとの通信には、Luvを使う socket.nvim を使っている。そのため、以下のプラグインに依存する:
https://github.com/stg73/socket.nvim (通信)
https://github.com/stg73/modules.nvim (socket.nvim が依存 SHA1など)
