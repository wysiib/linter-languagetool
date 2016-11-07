module.exports = class LinterProvider
  lint: (TextEditor) ->
    new Promise (Resolve) ->
      toReturn = []

      editorPath = TextEditor.getPath()
      editorContent = TextEditor.getText()
      textBuffer = TextEditor.getBuffer()

      https = require('https');
      options = {
        hostname: 'languagetool.org',
        path: '/api/v2/check?language=auto&text=' + encodeURIComponent editorContent,
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
          'Accept': 'application/json'
        }
      };

      req = https.request options, (res) ->
        res.on 'data', (chunk) ->
          jsonObject = JSON.parse chunk
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
              range: [startPos,endPos],
              severity: 'error'
            }
          Resolve toReturn
      req.end()
