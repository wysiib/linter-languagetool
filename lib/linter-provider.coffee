child_process = require 'child_process'
querystring = require 'querystring'
net = require 'net'
{Disposable} = require 'atom'

module.exports = class LinterProvider
  server_started = false
  server_port = 0
  categries_map = {
    'CASING': 'error'
    'COLLOCATIONS': 'error'
    'COLLOQUIALISMS': 'info'
    'COMPOUNDING': 'error'
    'CONFUSED_WORDS': 'info'
    'CORRESPONDENCE': 'error'
    'EMPFOHLENE_RECHTSCHREIBUNG': 'info'
    'FALSE_FRIENDS': 'info'
    'GENDER_NEUTRALITY': 'info'
    'GRAMMAR': 'error'
    'HILFESTELLUNG_KOMMASETZUNG': 'warning'
    'IDIOMS': 'info'
    'MISC': 'warning'
    'MISUSED_TERMS_EU_PUBLICATIONS': 'warning'
    'NONSTANDARD_PHRASES': 'info'
    'PLAIN_ENGLISH': 'info'
    'PROPER_NOUNS': 'error'
    'PUNCTUATION': 'error'
    'REDUNDANCY': 'error'
    'REGIONALISMS': 'info'
    'REPETITIONS': 'info'
    'SEMANTICS': 'warning'
    'STYLE': 'info'
    'TYPOGRAPHY': 'warning'
    'TYPOS': 'error'
    'WIKIPEDIA': 'info'
  }

  constructor: ->
    if atom.config.get 'linter-languagetool.languagetoolServerPath'
      ltoptions = ''
      if atom.config.get 'linter-languagetool.configFilePath'
        ltoptions = ltoptions + ' --config ' + atom.config.get 'linter-languagetool.configFilePath'
      ltjar = atom.config.get 'linter-languagetool.languagetoolServerPath'

      ltserver = net.createServer (socket) ->
        console.log("Creating Server")
        {
          reader: socket,
          writer: socket
        }
      .on 'error', (err) ->
        throw err

      ltserver.listen () ->
        server_port = ltserver.address().port.toString()
        console.log("Grabbed port: " + server_port)
        process = child_process.spawn 'java', ['-cp', ltjar, 'org.languagetool.server.HTTPServer', '--port', server_port, ltoptions,'"$@"']

        process.stdout.on 'data', (data) ->
          console.log data

        server_started = true


  lint: (TextEditor) ->
    new Promise (Resolve) ->
      received = ""
      toReturn = []

      editorPath = TextEditor.getPath()
      editorContent = TextEditor.getText()
      textBuffer = TextEditor.getBuffer()

      if atom.config.get 'linter-languagetool.languagetoolServerPath'
        lthostname = 'localhost'
        http = require('http')
        apipath = '/v2'
        ltport = server_port
      else
        http = require('https')
        apipath = '/api/v2'
        lthostname = 'languagetool.org'
        ltport = 443

      post_data_dict = {
        'language': 'auto'
        'text': editorContent
        'motherTongue': atom.config.get 'linter-languagetool.motherTongue'
      }

      if (atom.config.get 'linter-languagetool.preferredVariants').length > 0
        post_data_dict['preferredVariants'] = atom.config.get('linter-languagetool.preferredVariants').join()
      if (atom.config.get 'linter-languagetool.disabledCategories').length > 0
        post_data_dict['disabledCategories'] = atom.config.get('linter-languagetool.disabledCategories').join()
      if (atom.config.get 'linter-languagetool.disabledRules').length > 0
        post_data_dict['disabledRules'] = atom.config.get('linter-languagetool.disabledRules').join()

      post_data = querystring.stringify post_data_dict

      options = {
        hostname: lthostname
        path: "#{apipath}/check"
        port: ltport
        method: 'POST'
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
          'Accept': 'application/json'
          'Content-Length': Buffer.byteLength(post_data)
        }
      }

      req = http.request options, (res) ->
        res.on 'data', (chunk) ->
          received = received + chunk
        res.on 'end', ->
          try
            jsonObject = JSON.parse received
          catch error
            atom.notifications.addError("Invalid output received from LanguageTool server", {detail: received})
            return Resolve toReturn

          matches = jsonObject["matches"]
          for match in matches
            offset = match['offset']
            length = match['length']
            startPos = textBuffer.positionForCharacterIndex offset
            endPos = textBuffer.positionForCharacterIndex(offset + length)

            description = "*#{match['rule']['description']}*\n\n(`ID: #{match['rule']['id']}`)"
            if match['shortMessage']
              description = "#{match['message']}\n\n#{description}"
            else

            replacements = match['replacements'].map (rep) ->
              {
                title: rep.value,
                position: [startPos, endPos],
                replaceWith: rep.value,
              }
            message = {
              location: {
                file: editorPath,
                position: [startPos, endPos],
              },
              severity: categries_map[match['rule']['category']['id']] or 'error'
              description: description,
              solutions: replacements,
              excerpt: match['shortMessage'] or match['message']
            }

            if match['rule']['urls']
              message['url'] = match['rule']['urls'][0]['value']

            toReturn.push message
          Resolve toReturn

      req.write(post_data)
      req.end()
