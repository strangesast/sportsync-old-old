app = require '../app'
debug = require('debug')('app:server');
http = require 'http'

normalizePort = (val) ->
  port = parseInt val, 10

  if isNaN port
    return val

  if port >= 0
    return port

  return false


onError = (error) ->
  unless error.syscall is 'listen'
    throw error

  bind = if typeof port is 'string' 
  then 'Pipe ' + port 
  else 'Port ' + port

  switch error.code
    when 'EACCES' 
      console.error bind + ' requires elevated privileges'
      process.exit 1
      break

    when 'EADDRINUSE'
      console.error bind + ' is already in use'
      process.exit 1
      break

    else
      throw error

onListening = ->
  addr = server.address()

  bind = if typeof addr is 'string'
  then 'pipe ' + addr
  else 'port ' + addr.port

  debug 'Listening on ' + bind


port = normalizePort process.env.PORT || '3000'
app.set 'port', port

server = http.createServer app

server.listen port
server.on 'error', onError
server.on 'listening', onListening
