---
layout: post
title:  "Async Bitcoin RPC client"
date:   2014-01-30 18:19:43 +0000
categories: async api bitcoin tornado
redirect_from:
  - /2014/async-bitcoin-rpc-client/
  - /blog/2014/01/30/async-bitcoin-rpc-client.html
---

<a class="github-button" href="https://github.com/st4lk/python-bitcoinrpc-tornado" data-color-scheme="no-preference: light; light: light; dark: dark;" data-size="large" data-show-count="true" aria-label="Star st4lk/python-bitcoinrpc-tornado on GitHub">Star</a>

To work with [Bitcoin RPC](https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list) from python there is a library [Python-BitcoinRPC](https://github.com/jgarzik/python-bitcoinrpc).

But recently i need to call API from tornado application. Mentioned lib works in synchronous, i.e. blocking mode. For tornado it will be much better to use asynchronous version. Tried to search for existing solution, but can't find it. So i create my async fork, that use tornado's AsyncHTTPClient: [https://github.com/st4lk/python-bitcoinrpc-tornado](https://github.com/st4lk/python-bitcoinrpc-tornado).

<!--more-->

Example (print current number of blocks in Bitcoin network):

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
