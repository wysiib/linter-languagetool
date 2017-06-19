child_process = require 'child_process'
querystring = require 'querystring'


module.exports = class LinterProvider
  server_started = false

  startserver = ->
    if server_started is false
      server_started = true
      ltjar = atom.config.get 'linter-languagetool.languagetoolServerPath'
      ltserver = child_process.exec 'java -cp ' + ltjar + ' org.languagetool.server.HTTPServer --public "$@"', (error, stdout, stderr) ->
        if error
          console.error error
        console.log stdout
        console.log stderr

        ltserver.stdout.on 'data', (data) ->
          console.log data


  magicCommentLanguageSetting = (content) ->
    magicCommentPattern = ///
      \%\s*!TeX\s* # Starting with %!TeX
      spellcheck\s*=\s*
      ([\w-]+) # capture language setting
    ///ig # ignore Case

    match = magicCommentPattern.exec content
    if match
      lang = match[1].replace /_/, '-'
    else
      'auto'




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
        apipath = '/v2'
        ltport = 8081
      else
        http = require('https')
        apipath = '/api/v2'
        lthostname = 'languagetool.org'
        ltport = 443

      language = magicCommentLanguageSetting editorContent
      console.log language

      post_data_dict = {
        'language': language
        'text': editorContent
        'motherTongue': atom.config.get 'linter-languagetool.motherTongue'
      }

      if (atom.config.get 'linter-languagetool.preferredVariants').length > 0
        post_data_dict['preferredVariants'] = atom.config.get('linter-languagetool.preferredVariants').join()

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
          jsonObject = JSON.parse received
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
              severity: 'error',
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
