{assert} = require('chai')
{spawn} = require('cross-spawn')
ps = require('ps-node')

{terminate, kill} = require('../../src/terminate-ps')

COFFEE_BIN = 'node_modules/.bin/coffee'
WAIT_AFTER_COMMAND_SPAWNED_MS = 500
WAIT_AFTER_COMMAND_TERMINATED_MS = 500


runProcess = (command, fn, callback) ->
  processInfo =
    childProcess: undefined
    stdout: ''
    stderr: ''
    terminated: false
    statusCode: undefined

  childProcess = spawn(COFFEE_BIN, [command])
  processInfo.childProcess = childProcess

  childProcess.stdout.on('data', (data) -> processInfo.stdout += data.toString())
  childProcess.stderr.on('data', (data) -> processInfo.stderr += data.toString())

  childProcess.on('close', (statusCode) ->
    processInfo.terminated = true
    processInfo.statusCode = statusCode
  )

  setTimeout( ->
    fn(processInfo, (args...) ->
      processInfo.callbackArgs = args

      setTimeout( ->
        childProcess.removeAllListeners('close')
        callback(null, processInfo)
      , WAIT_AFTER_COMMAND_TERMINATED_MS)
    )
  , WAIT_AFTER_COMMAND_SPAWNED_MS)


cleanUpProcess = (pid, callback) ->
  ps.kill(pid, {signal: 9}, -> callback())


describe.only('Terminating Processes', ->
  describe('#terminate', ->
    describe('process with support for graceful termination', ->
      processInfo = undefined

      beforeEach((done) ->
        runProcess('test/fixtures/scripts/stdout.coffee', ({childProcess}, next) ->
          terminate(childProcess, next)
        , (err, info) ->
          processInfo = info
          done(err)
        )
      )
      afterEach((done) ->
        cleanUpProcess(processInfo.childProcess.pid, done)
      )

      it('logs a message about being gracefully terminated', ->
        assert.include(processInfo.stdout, 'exiting')
      )
      it('gets terminated', ->
        assert.isTrue(processInfo.terminated)
      )
      it('returns zero status code', ->
        assert.equal(processInfo.statusCode, 0)
      )
      it('the callback gets called with no arguments', ->
        assert.deepEqual(processInfo.callbackArgs, [])
      )
    )

    describe('process without support for graceful termination', ->
      processInfo = undefined

      beforeEach((done) ->
        runProcess('test/fixtures/scripts/endless-ignore-term.coffee', ({childProcess}, next) ->
          terminate(childProcess, next)
        , (err, info) ->
          processInfo = info
          done(err)
        )
      )
      afterEach((done) ->
        cleanUpProcess(processInfo.childProcess.pid, done)
      )

      it('logs a message about ignoring the graceful termination attempt', ->
        assert.include(processInfo.stdout, 'ignoring')
      )
      it('does not get terminated', ->
        assert.isFalse(processInfo.terminated)
      )
      it('has undefined status code', ->
        assert.isUndefined(processInfo.statusCode)
      )
      it('the callback has one argument', ->
        assert.equal(processInfo.callbackArgs.length, 1)
      )
      it('the first callback argument is an error', ->
        assert.instanceOf(processInfo.callbackArgs[0], Error)
      )
      it('the error has a message about unsuccessful termination', ->
        assert.equal(
          processInfo.callbackArgs[0].message,
          "Unable to gracefully terminate process #{processInfo.childProcess.pid}"
        )
      )
    )

    describe('with the force option', ->
      describe('process with support for graceful termination', ->
        processInfo = undefined

        beforeEach((done) ->
          runProcess('test/fixtures/scripts/stdout.coffee', ({childProcess}, next) ->
            terminate(childProcess, {force: true}, next)
          , (err, info) ->
            processInfo = info
            done(err)
          )
        )
        afterEach((done) ->
          cleanUpProcess(processInfo.childProcess.pid, done)
        )

        it('logs a message about being gracefully terminated', ->
          assert.include(processInfo.stdout, 'exiting')
        )
        it('gets terminated', ->
          assert.isTrue(processInfo.terminated)
        )
        it('returns zero status code', ->
          assert.equal(processInfo.statusCode, 0)
        )
        it('the callback gets called with no arguments', ->
          assert.deepEqual(processInfo.callbackArgs, [])
        )
      )

      describe('process without support for graceful termination', ->
        processInfo = undefined

        beforeEach((done) ->
          runProcess('test/fixtures/scripts/endless-ignore-term.coffee', ({childProcess}, next) ->
            terminate(childProcess, {force: true}, next)
          , (err, info) ->
            processInfo = info
            done(err)
          )
        )
        afterEach((done) ->
          cleanUpProcess(processInfo.childProcess.pid, done)
        )

        it('logs a message about ignoring the graceful termination attempt', ->
          assert.include(processInfo.stdout, 'ignoring')
        )
        it('gets terminated', ->
          assert.isTrue(processInfo.terminated)
        )
        it('returns no status code', ->
          assert.isNull(processInfo.statusCode)
        )
        it('the callback gets called with no arguments', ->
          assert.deepEqual(processInfo.callbackArgs, [])
        )
      )
    )
  )

  describe('#kill', ->
    describe('process with support for graceful termination', ->
      processInfo = undefined

      beforeEach((done) ->
        runProcess('test/fixtures/scripts/stdout.coffee', ({childProcess}, next) ->
          kill(childProcess, next)
        , (err, info) ->
          processInfo = info
          done(err)
        )
      )
      afterEach((done) ->
        cleanUpProcess(processInfo.childProcess.pid, done)
      )

      it('does not log a message about being gracefully terminated', ->
        assert.notInclude(processInfo.stdout, 'exiting')
      )
      it('gets terminated', ->
        assert.isTrue(processInfo.terminated)
      )
      it('returns no status code', ->
        assert.isNull(processInfo.statusCode)
      )
      it('the callback gets called with no arguments', ->
        assert.deepEqual(processInfo.callbackArgs, [])
      )
    )

    describe('process without support for graceful termination', ->
      processInfo = undefined

      beforeEach((done) ->
        runProcess('test/fixtures/scripts/endless-ignore-term.coffee', ({childProcess}, next) ->
          kill(childProcess, next)
        , (err, info) ->
          processInfo = info
          done(err)
        )
      )
      afterEach((done) ->
        cleanUpProcess(processInfo.childProcess.pid, done)
      )

      it('does not log a message about ignoring graceful termination', ->
        assert.notInclude(processInfo.stdout, 'ignoring')
      )
      it('gets terminated', ->
        assert.isTrue(processInfo.terminated)
      )
      it('returns no status code', ->
        assert.isNull(processInfo.statusCode)
      )
      it('the callback gets called with no arguments', ->
        assert.deepEqual(processInfo.callbackArgs, [])
      )
    )
  )
)
