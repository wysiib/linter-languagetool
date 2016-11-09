module.exports = LinterLanguagetool =
  config:
    languagetoolServerPath:
      title: 'Path to local languagetool-server.jar'
      description: 'If given, the linter tries to start a local languagetool server and connect to it. If left blank, the public languagetool API is used instead.'
      type: 'string'
      default: ''
    grammerScopes:
      type: 'array'
      description: 'This preference holds a list of grammar scopes languagetool should be applied to.'
      default: ['text.tex.latex', 'source.asciidoc', 'source.gfm', 'text.git-commit', 'text.plain', 'text.plain.null-grammar']
      items:
        type: 'string'

  provideLinter: ->
    LinterProvider = require './linter-provider'
    provider = new LinterProvider()
    return {
      name: 'languagetool'
      scope: 'file'
      lintsOnChange: true
      grammarScopes: atom.config.get 'linter-languagetool.grammerScopes'
      lint: provider.lint
    }
