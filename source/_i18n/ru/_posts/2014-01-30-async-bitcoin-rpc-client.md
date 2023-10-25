---
layout: post
title:  "Асинхронный Bitcoin RPC клиент на python"
date:   2014-01-30 18:19:43 +0000
categories: async api bitcoin tornado
redirect_from:
  - /2014/async-bitcoin-rpc-client/
  - /blog/2014/01/30/async-bitcoin-rpc-client.html
---

<a class="github-button" href="https://github.com/st4lk/python-bitcoinrpc-tornado" data-color-scheme="no-preference: light; light: light; dark: dark;" data-size="large" data-show-count="true" aria-label="Star st4lk/python-bitcoinrpc-tornado on GitHub">Star</a>

Для работы с [Bitcoin RPC](https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list) на python'е есть библиотека [Python-BitcoinRPC](https://github.com/jgarzik/python-bitcoinrpc).

Но недавно мне понадобилось обратиться к API из приложения на tornado. Указанная библиотека работает в синхронном, т.е. блокирующем режиме. Для торнадо было бы намного лучше использовать асинхронную версию. Готовой найти не удалось, поэтому написал свой форк - асинхронный, который использует торнадовский AsyncHTTPClient: [https://github.com/st4lk/python-bitcoinrpc-tornado](https://github.com/st4lk/python-bitcoinrpc-tornado).

<!--more-->

Пример (выводит текущее количество блоков в сети Bitcoin):

```python
from bitcoinrpc_async.authproxy import AsyncAuthServiceProxy
from tornado import ioloop, gen

BITCOIN_RPC_URL = "http://user:password@127.0.0.1:8332"

@gen.coroutine
def show_block_count():
    service = AsyncAuthServiceProxy(BITCOIN_RPC_URL)
    result = yield service.getblockcount()
    print result


io_loop = ioloop.IOLoop.instance()
io_loop.add_callback(show_block_count)
io_loop.start()
```
