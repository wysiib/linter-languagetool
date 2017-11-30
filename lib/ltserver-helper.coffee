{BufferedProcess, CompositeDisposable} = require 'atom'

class LTServerHelper
  
  constructor: ->
    @disposables = new CompositeDisposable
    @ltserver = undefined
    if atom.config.get 'linter-languagetool.languagetoolServerPath'
      @startserver()
    
    # Register for LanguageServer Settings Changes
    @disposables.add atom.config.onDidChange 'linter-languagetool.languagetoolServerPath', ({newValue, oldValue}) =>
      if newValue
        @stopserver()
        @startserver()
      else
        @stopserver()
        
    @disposables.add atom.config.onDidChange 'linter-languagetool.configFilePath', ({newValue, oldValue}) =>
      @stopserver()
      @startserver()
  
  destroy: ->
    @stopserver()
    @disposables.dispose()
  
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