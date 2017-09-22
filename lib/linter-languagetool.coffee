module.exports = LinterLanguagetool =
  config:
    languagetoolServerPath:
      title: 'Path to local languagetool-server.jar'
      description: 'If given, the linter tries to start a local languagetool server and connect to it. If left blank, the public languagetool API is used instead.'
      type: 'string'
      default: ''
    configFilePath:
      title: 'Path to a config file'
      description: 'Path to a configuration file for the LanguageTool server. Can be used to provide the path to the n-gram data to LanugageTool. If given, LanguageTool can detect errors with words that are often confused, like *their* and *there*. See [LanguageTool Wiki](http://wiki.languagetool.org/finding-errors-using-n-gram-data) for more information'
      type: 'string'
      default: ''
    grammerScopes:
      type: 'array'
      description: 'This preference holds a list of grammar scopes languagetool should be applied to.'
      default: ['text.tex.latex', 'source.asciidoc', 'source.gfm', 'text.git-commit', 'text.plain', 'text.plain.null-grammar']
      items:
        type: 'string'
    preferredVariants:
      type: 'array'
      description: 'List of preferred language variants. The language detector used with language=auto can detect e.g. English, but it cannot decide whether British English or American English is used. Thus this parameter can be used to specify the preferred variants like en-GB and de-AT. Only available with language=auto.'
      default: []
      items:
        type: 'string'
    disabledCategories:
      type: 'array'
      description: 'List of LanguageTool rule categories to be disabled.'
      default: []
      items:
        type: 'string'
    disabledRules:
      type: 'array'
      description: 'List of LanguageTool rules to be disabled.'
      default: []
      items:
        type: 'string'
    motherTongue:
      type: 'string'
      description: 'A language code of the user\'s native language, enabling false friends checks for some language pairs.'
      default: require('electron').remote.app.getLocale()
    lintsOnChange:
      type: 'boolean'
      description: 'If enabled the linter will run on every change on the file.'
      default: false

  provideLinter: ->
    LinterProvider = require './linter-provider'
    provider = new LinterProvider()
    return {
      name: 'languagetool'
      scope: 'file'
      lintsOnChange: atom.config.get 'linter-languagetool.lintsOnChange'
      grammarScopes: atom.config.get 'linter-languagetool.grammerScopes'
      lint: provider.lint
    }
