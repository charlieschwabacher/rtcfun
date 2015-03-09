ws = require 'ws'
WebSocketServer = ws.Server

module.exports = class WSServer

  constructor: ->
    @wss = new WebSocketServer port: 3002
    @handlers = {}
    @sockets = {}

    idCounter = 0

    @wss.on 'connection', (ws) =>
      id = idCounter += 1
      @sockets[id] = ws

      handler id for handler in @handlers.open if @handlers.open?

      ws.addEventListener 'close', (e) =>
        delete @sockets[id]
        handler id for handler in @handlers.close if @handlers.close?

      ws.addEventListener 'message', (e) =>
        [type, payload] = JSON.parse e.data
        handler id, payload for handler in @handlers[type] if @handlers[type]?

  on: (type, callback) ->
    @handlers[type] ||= []
    @handlers[type].push callback

  off: (type, callback) ->
    return unless @handlers[type]?
    index = @handlers[type].indexOf callback
    @handlers[type].splice index, 1 if index isnt -1

  send: (id, type, payload) ->
    @sockets[id].send JSON.stringify [type, payload]

  close: ->
    @wss.close()
