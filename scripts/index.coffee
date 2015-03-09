WS = require './ws'
RTCPeerConnection = webkitRTCPeerConnection or mozRTCPeerConnection
SessionDescription = RTCSessionDescription or mozRTCSessionDescription


require('build-status').client() if process.env.NODE_ENV is 'development'


ws = new WS 'ws://localhost:3002'
servers = iceServers: [url: 'stun:stun.l.google.com:19302']
config = optional: [RtpDataChannels: true]

pendingConnections = {}
peers = {}


addPendingConnection = (room, id, connection) ->
  pendingConnections[room] ||= []
  pendingConnections[room][id] = connection

removePendingConnection = (room, id) ->
  delete pendingConnections[room][id]
  delete pendingConnections[room] if pendingConnections[room].length is 0

setupDataChannel = (room, id, dataChannel) ->
  console.log 'setting up data channel'
  console.log dataChannel
  peers[room] ||= []
  peers[room][id] = dataChannel


ws.on 'open', ->
  console.log 'socket opened'
  ws.send 'join', 'lobby'


ws.on 'request offer', ({room, from}) ->
  console.log 'received request for offer'
  pc = new RTCPeerConnection servers, config

  pc.onicecandidate = (e) ->
    console.log 'ice candidate!'
    console.log e
    console.log e.candidate
    console.log Object.keys e.candidate

  pc.oniceconnectionstatechange = (e) ->
    console.log 'ice connection state change'
    console.log e

  pc.createOffer (localDescription) ->
    pc.setLocalDescription localDescription, ->
      sdp = localDescription.sdp
      to = from
      ws.send 'offer', {room, sdp, to}

  addPendingConnection room, from, pc


ws.on 'offer', ({room, from, sdp}) ->
  console.log 'received offer'

  pc = new RTCPeerConnection servers, config
  pc.onicecandidate = (e) ->
    console.log 'ice candidate!'
  console.log pc

  remoteDescription = new SessionDescription {sdp, type: 'offer'}
  pc.setRemoteDescription remoteDescription, ->
    pc.createAnswer (localDescription) ->
      pc.setLocalDescription localDescription, ->
        sdp = localDescription.sdp
        to = from
        ws.send 'answer', {room, sdp, to}

  pc.addEventListener 'datachannel', (e) ->
    console.log 'received datachannel'
    console.log e
    removePendingConnection room, from

  addPendingConnection room, from, pc


ws.on 'answer', ({room, from, sdp}) ->
  console.log 'received answer'
  pc = pendingConnections[room][from]
  remoteDescription = new SessionDescription {sdp, type: 'answer'}
  pc.setRemoteDescription remoteDescription, ->
    console.log 'creating data channel'
    dc = pc.createDataChannel "#{room}:#{from}", ordered: false
    dc.addEventListener 'error', ->
      console.log 'data channel error'
      console.log arguments
    dc.addEventListener 'open', ->
      console.log 'data channel opened'
      removePendingConnection room, from
      setupDataChannel room, from, dc


