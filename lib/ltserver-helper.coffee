{BufferedProcess, CompositeDisposable} = require 'atom'
url = require 'url'
rp = require 'request-promise-native'

class LTServerHelper
  PUBLIC_LT_URL = 'https://languagetool.org/api/v2/check'
  
  constructor: ->
    @disposables = new CompositeDisposable
    @ltserver = undefined
    @url = PUBLIC_LT_URL
    @ltinfo = undefined
    
    @handlelanguagetoolServerPathSetting()
    
    # Register for LanguageServer Settings Changes
    @disposables.add atom.config.onDidChange 'linter-languagetool.languagetoolServerPath', ({newValue, oldValue}) =>
      @handlelanguagetoolServerPathSetting()
        
    @disposables.add atom.config.onDidChange 'linter-languagetool.configFilePath', ({newValue, oldValue}) =>
      @handlelanguagetoolServerPathSetting()
  
  destroy: ->
    @stopserver()
    @disposables.dispose()
    
  handlelanguagetoolServerPathSetting: ->
    path = atom.config.get 'linter-languagetool.languagetoolServerPath'
    @stopserver()
    if path?.endsWith('.jar')
      # Default local server
      @url = 'http://localhost:8081/v2/check'
      @startserver()
    else if path?.startsWith('http')
      # Should be an url
      @url = url.resolve(path, 'v2/check')
    else
      # Default to the public server
      @url = PUBLIC_LT_URL
    # Getting the Serverinfo to check the settings
    @getServerInfo().then( (info) ->
      console.log('linter-languagetool ready to lint')
    ).catch( (error) ->
      console.log('unable to lint with linter-languagetool')
    )
      
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
          @ltinfo = data.software
          resolve(@ltinfo)
        )
        .catch( (err) =>
          console.log(err)
          @ltinfo = undefined
          if @url is PUBLIC_LT_URL
            # The public server fails
            atom.notifications.addError("""The public languagetool server is
              not responding. The linter will be disabled.""",
              {detail: err.message})
            reject(err)
          else
            # Some local error use the public server
            atom.notifications.addWarning("""There is some problem with your
              langugetool server. The linter will use the public url.""",
              {detail: err.message})
            @url = PUBLIC_LT_URL
            # run again the check
            @getServerInfo().then( (info) ->
              resolve(info)
            ).catch( (err)
              reject(err)
            )
        )
      )
    
  startserver: ->
    ltoptions = ''
    if atom.config.get 'linter-languagetool.configFilePath'
      ltoptions = ltoptions + ' --config ' + atom.config.get 'linter-languagetool.configFilePath'
    ltjar = atom.config.get 'linter-languagetool.languagetoolServerPath'
       
    command = 'java'
    if process.platform is 'win32'
      command = 'javaw'
       
    @ltserver = new BufferedProcess({
      command: command
      args: ['-cp', ltjar, 'org.languagetool.server.HTTPServer', ltoptions]
      options:
        detached: true,
        stdio: 'ignore'
    })
         
  stopserver: ->
    @ltserver?.kill()
    
module.exports = new LTServerHelper()