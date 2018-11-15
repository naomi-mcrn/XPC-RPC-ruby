XPC-RPC-ruby
=====================

Usage
--------------------
```
 require './lib/xpc'
 cli = XPC::RPC::Client.new("user" => "rpcuser", "pass" => "rpcpassword")
 ret = cli.execrpc("getinfo")
```

XP版 (https://github.com/naomi-mcrn/XP-RPC-ruby) のXPChain対応。
とりあえず最小限動くだけ。煮るなり焼くなり好きにして。
※急遽対応したので、コマンドチェック等がザルです。