readline = require('readline')


ignore = ->
  console.log('ignoring termination')

# Windows
rl = readline.createInterface({input: process.stdin, output: process.stdout})
rl.on('SIGINT', ignore)

# UNIX
process.on('SIGTERM', ignore)


setInterval(( -> ), 1000)
