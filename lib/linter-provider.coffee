child_process = require 'child_process'
querystring = require 'querystring'


module.exports = class LinterProvider
  @server_started: false

  startserver = ->
    if not server_started
      server_started = true
      ltjar = atom.config.get 'linter-languagetool.languagetoolServerPath'
      ltserver = child_process.exec 'java -cp ' + ltjar + ' org.languagetool.server.HTTPServer "$@"', (error, stdout, stderr) ->
        if error
          console.error error
        console.log stdout
        console.log stderr

        ltserver.stdout.on 'data', (data) ->
          console.log data


  lint: (TextEditor) ->
    new Promise (Resolve) ->
      received = ""
      toReturn = []

      editorPath = TextEditor.getPath()
      editorContent = TextEditor.getText()
      textBuffer = TextEditor.getBuffer()

      if atom.config.get 'linter-languagetool.languagetoolServerPath'
        startserver()
        lthostname = 'localhost'
        http = require('http')
        apipath = ''
        ltport = 8081
      else
        http = require('https')
        apipath = '/api'
        lthostname = 'languagetool.org'
        ltport = 443

      post_data = querystring.stringify {
        'language': 'auto'
        'text': editorContent
      }

      options = {
        hostname: lthostname
        path: "#{apipath}/v2/check"
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
          jsonObject = JSON.parse received
          matches = jsonObject["matches"]
          for match in matches
            offset = match['offset']
            length = match['length']
            startPos = textBuffer.positionForCharacterIndex offset
            endPos = textBuffer.positionForCharacterIndex(offset + length)
            toReturn.push {
              type: 'Error',
              text: match['message'],
              filePath: editorPath,
              range: [startPos, endPos],
              severity: 'error'
            }
          Resolve toReturn

      req.write(post_data)
      req.end()
