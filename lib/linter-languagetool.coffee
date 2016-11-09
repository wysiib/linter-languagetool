module.exports = LinterLanguagetool =
  config:
    languagetoolServerPath:
      title: 'Path to local languagetool-server.jar'
      description: 'If given, the linter tries to start a local languagetool server and connect to it. If left blank, the public languagetool API is used instead.'
      type: 'string'
      default: ''

  provideLinter: ->
    LinterProvider = require './linter-provider'
    provider = new LinterProvider()
    return {
      name: 'languagetool'
      scope: 'file'
      lintsOnChange: true
      grammarScopes: ['text.tex.latex', 'source.asciidoc', 'source.gfm', 'text.git-commit', 'text.plain', 'text.plain.null-grammar']
      lint: provider.lint
    }
