
ps = require('ps-node')


kill = (childProcess, callback) ->
  if process.platform is 'win32'
    childProcess.kill('SIGKILL')
    process.nextTick(callback)
  else
    ps.kill(childProcess.pid, {signal: 9}, -> callback())


term = (childProcess) ->
  if process.platform is 'win32'
    childProcess.stdin.write('\x03') # Ctrl+C
  else
    childProcess.kill('SIGTERM')


# Gracefully terminates a process with given PID
#
# Sends a signal to the process as a heads up it should terminate.
# Then checks multiple times whether the process terminated. Retries
# sending the signal. In case it's not able to terminate the process
# within given timeout, it calls the callback with an error.
#
# If provided with the 'force' option, instead of returning an error,
# it kills the process unconditionally.
terminate = (childProcess, options, callback) ->
  [callback, options] = [options, {}] if typeof options is 'function'

  options.force ?= false
  options.timeout ?= 1000
  options.retry ?= 500

  terminated = false
  childProcess.on('exit', -> terminated = true)

  start = Date.now()
  term(childProcess)

  check = ->
    if terminated
      clearTimeout(timeout)
      callback()
    else
      if (Date.now() - start) < options.timeout
        term(childProcess)
        timeout = setTimeout(check, options.retry)
      else
        clearTimeout(timeout)
        if options.force
          kill(childProcess, callback)
        else
          callback(new Error("Unable to gracefully terminate process #{childProcess.pid}"))

  timeout = setTimeout(check, 1)


module.exports = {
  kill
  terminate
}
