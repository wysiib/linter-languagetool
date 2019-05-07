{BufferedProcess, CompositeDisposable, Emitter} = require 'atom'
url = require 'url'
fs = require 'fs'
rp = require 'request-promise-native'

class LTServerHelper
  PUBLIC_LT_URL = 'https://languagetool.org/api/v2/check'

  init: ->
    @disposables = new CompositeDisposable
    @emitter = new Emitter
    @url = PUBLIC_LT_URL

    # Register for LanguageServer Settings Changes
    @disposables.add atom.config.onDidChange 'linter-languagetool.languagetoolServerPath', ({newValue, oldValue}) =>
      @handlelanguagetoolServerPathSetting()

    @disposables.add atom.config.onDidChange 'linter-languagetool.configFilePath', ({newValue, oldValue}) =>
      @handlelanguagetoolServerPathSetting()

    @disposables.add atom.config.onDidChange 'linter-languagetool.languagetoolServerPort', ({newValue, oldValue}) =>
      @handlelanguagetoolServerPathSetting()

    return @handlelanguagetoolServerPathSetting()

  destroy: ->
    @stopserver()
    @disposables.dispose()
    @disposables = null
    @emitter.dispose()
    @emitter = null

  onDidChangeLTInfo: (callback) ->
    @emitter.on 'did-change-ltinfo', callback

  setltinfo: (info) ->
    if info isnt @ltinfo
      @ltinfo = info
      @emitter.emit 'did-change-ltinfo', @ltinfo
    @ltinfo

  useLTServerWithUrl: (url) ->
    @url = url
    return new Promise( (resolve, reject) =>
      @getServerInfo().then( (info) ->
        resolve(info)
      ).catch( (err) =>
        if @url is PUBLIC_LT_URL
          # The public server fails
          atom.notifications.addError("""The public languagetool server is
            not responding. The linter will be disabled.""",
            {detail: err.message})
          reject(err)
        else if atom.config.get 'linter-languagetool.fallbackToPublicApi'
          # Some local error, use the public server
          atom.notifications.addWarning("""There is some problem with your
            langugetool server. The linter will use the public url.""",
            {detail: err.message})
          @url = PUBLIC_LT_URL
          @getServerInfo().then( (info) ->
            resolve(info)
          ).catch( (err) ->
            atom.notifications.addError("""The public languagetool server is
              not responding. The linter will be disabled.""",
              {detail: err.message})
            reject(err)
          )
        else
          atom.notifications.addError("""There is some problem with your
            langugetool server. The linter will not use the public url and
            hence might not work correctly.""",
            {detail: err.message})
          reject(err)
      )
    )

  handlelanguagetoolServerPathSetting: ->
    path = atom.config.get 'linter-languagetool.languagetoolServerPath'
    @stopserver()
    @setltinfo(undefined)

    if path?.startsWith('http')
      return @useLTServerWithUrl( url.resolve(path, 'v2/check') )

    if path?.endsWith('.jar')
      # Test if the file exits
      try
        fs.accessSync(path)
      catch
        atom.notifications.addWarning("""#{path} not found. Using
        public server.""")
        return @useLTServerWithUrl(PUBLIC_LT_URL)
      return new Promise( (resolve, reject) =>
        port = atom.config.get('linter-languagetool.languagetoolServerPort')
        port = 8081 unless port?
        @startserver(port).then(  =>
          @useLTServerWithUrl("http://localhost:#{port}/v2/check").then( ->
            resolve()
          )
        ).catch( =>
          console.log("exception")
          @stopserver()
          atom.notifications.addWarning("""Unable to start the local
          server. Using the public server.""")
          @useLTServerWithUrl(PUBLIC_LT_URL).then( ->
            resolve()
          )
        )
      )
    # Default return
    return @useLTServerWithUrl(PUBLIC_LT_URL)

  getServerInfo: ->
    options = {
      method: 'POST',
      uri: @url,
      form:
        language: 'en-US'
        text: 'a simple test'
      json: true
    }
    return new Promise ( (resolve, reject) =>
      rp(options)
        .then( (data) =>
          @setltinfo(data.software)
          @emitter.emit 'did-change-ltinfo', @ltinfo
          resolve(@ltinfo)
        )
        .catch( (err) ->
          reject(err)
        )
      )

  startserver: (port = 8081) ->
    ltjar = atom.config.get 'linter-languagetool.languagetoolServerPath'

    command = 'java'
    if process.platform is 'win32'
      command = 'javaw'

    jvmoptions = []
    if atom.config.get 'linter-languagetool.jvmOptions'
      jvmoptions = [atom.config.get 'linter-langugetool.jvmOptions']

    args = jvmoptions.concat ['-cp', ltjar, 'org.languagetool.server.HTTPServer', '--port', port]
    if atom.config.get 'linter-languagetool.configFilePath'
      args.push ['--config', atom.config.get 'linter-languagetool.configFilePath']...

    return new Promise( (resolve, reject) =>
      stdout = (output) ->
        if /Server started/.test(output)
          resolve()
      stderr = (output) ->

      exit = (output) ->
        # Can be a for example port errors, if another server is already running
        # or config file not found errors.
        reject()

      @ltserver = new BufferedProcess({
        command: command
        args: args
        options:
          detached: true
        stdout: stdout
        stderr: stderr
        exit: exit
      })
    )

  stopserver: ->
    @ltserver?.kill()
    @ltserver = undefined

module.exports = new LTServerHelper()
