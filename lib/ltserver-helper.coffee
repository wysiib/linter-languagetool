{BufferedProcess, CompositeDisposable} = require 'atom'
url = require 'url'

class LTServerHelper
  
  constructor: ->
    @disposables = new CompositeDisposable
    @ltserver = undefined
    @url = 'https://languagetool.org/api/v2/check'
    
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
      @url = 'https://languagetool.org/api/v2/check'
       
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