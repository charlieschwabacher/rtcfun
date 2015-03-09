WSServer = require './ws_server'


module.exports = class SignalingServer


  constructor: ->

    @wss = new WSServer
    @rooms = {}
    @memberships = {}


    @wss.on 'open', (id) =>
      console.log "opened connection to #{id}"

      @memberships[id] = []


    @wss.on 'close', (id) =>
      console.log "closed connection to #{id}"

      for room in @memberships[id]
        index = @rooms[room].indexOf id
        @rooms[room].splice index, 1 if index isnt -1

      delete @memberships[id]


    @wss.on 'leave', (id, room) =>
      console.log "client #{id} left #{room}"

      i = @memberships[id].indexOf room
      @memberships[id].splice i, 1 if i isnt -1
      j = @rooms[room].indexOf id
      @rooms[room].slice j, 1 if j isnt -1


    @wss.on 'join', (id, room) =>
      console.log "client #{id} joined #{room}"
      @rooms[room] ||= []

      for peer in @rooms[room]
        @wss.send peer, 'request offer', {room, from: id}

      @memberships[id].push room
      @rooms[room].push id


    @wss.on 'offer', (id, {sdp, room, to}) =>
      console.log "client #{id} sent offer to #{to} in #{room}"
      @wss.send to, 'offer', {sdp, room, from: id}


    @wss.on 'answer', (id, {sdp, room, to}) =>
      console.log "client #{id} sent answer to #{to} in #{room}"
      @wss.send to, 'answer', {sdp, room, from: id}



  stop: ->
    @wss.close()
