express = require 'express'
readline = require 'readline'


ignore = ->
  console.log('ignoring termination')

# Windows
rl = readline.createInterface({input: process.stdin, output: process.stdout})
rl.on('SIGINT', ignore)

# UNIX
process.on('SIGTERM', ignore)


app = express()

app.get '/machines', (req, res) ->
  res.json [{type: 'bulldozer', name: 'willy'}]

app.get '/machines/:name', (req, res) ->
  res.json {type: 'bulldozer', name: req.params.name}

app.listen process.argv[2], ->
  console.log "Dummy server listening on port #{process.argv[2]}!"
