module.exports = class WS

  constructor: (url) ->
    @ws = new WebSocket url
    @handlers = {}

    @ws.addEventListener 'open', =>
      handler() for handler in @handlers.open if @handlers.open?

    @ws.addEventListener 'close', =>
      handler() for handler in @handlers.close if @handlers.close?

    @ws.addEventListener 'message', (e) =>
      [type, payload] = JSON.parse e.data
      handler payload for handler in @handlers[type] if @handlers[type]?

  on: (type, callback) ->
    @handlers[type] ||= []
    @handlers[type].push callback

  off: (type, callback) ->
    return unless @handlers[type]?
    index = @handlers[type].indexOf callback
    @handlers[type] = @handlers[type].splice index, 1 if index isnt -1

  send: (type, payload) ->
    @ws.send JSON.stringify [type, payload]
