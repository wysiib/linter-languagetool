rp = require 'request-promise-native'
lthelper = require './ltserver-helper'


module.exports = class LinterProvider
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

  getPostDataDict= (editorContent) ->

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

    return post_data_dict

  linterMessagesForData= (data, textBuffer, editorPath) ->
    messages = []

    matches = data["matches"]
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

      messages.push message
    return messages

  lint: (TextEditor) ->

    new Promise (resolve) ->
      if not lthelper.ltinfo
        # Disable the linter if the server is not responding
        resolve([])
        return

      post_data = getPostDataDict(TextEditor.getText())

      options = {
        method: 'POST',
        uri: lthelper.url,
        form: post_data,
        json: true
      }

      editorPath = TextEditor.getPath()
      textBuffer = TextEditor.getBuffer()

      rp(options)
        .then( (data) ->
          messages = linterMessagesForData(data, textBuffer, editorPath)
          resolve(messages)
        )
        .catch( (err) ->
          console.log(err)
          atom.notifications.addError("Invalid output received from LanguageTool server", {detail: err.message})
          resolve([])
        )
