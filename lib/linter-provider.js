'use babel'

import rp from 'request-promise-native';
import lthelper from './ltserver-helper';

const categries_map = {
    'CASING': 'error',
    'COLLOCATIONS': 'error',
    'COLLOQUIALISMS': 'info',
    'COMPOUNDING': 'error',
    'CONFUSED_WORDS': 'info',
    'CORRESPONDENCE': 'error',
    'EMPFOHLENE_RECHTSCHREIBUNG': 'info',
    'FALSE_FRIENDS': 'info',
    'GENDER_NEUTRALITY': 'info',
    'GRAMMAR': 'error',
    'HILFESTELLUNG_KOMMASETZUNG': 'warning',
    'IDIOMS': 'info',
    'MISC': 'warning',
    'MISUSED_TERMS_EU_PUBLICATIONS': 'warning',
    'NONSTANDARD_PHRASES': 'info',
    'PLAIN_ENGLISH': 'info',
    'PROPER_NOUNS': 'error',
    'PUNCTUATION': 'error',
    'REDUNDANCY': 'error',
    'REGIONALISMS': 'info',
    'REPETITIONS': 'info',
    'SEMANTICS': 'warning',
    'STYLE': 'info',
    'TYPOGRAPHY': 'warning',
    'TYPOS': 'error',
    'WIKIPEDIA': 'info'
};
const prev_scopes_ignore_rules = [
    'DE_CASE'
];

class LinterProvider {

    constructor (grammarProvider) {
        this.grammarManager = grammarProvider;
    }

    getPostDataDict (TextEditor) {

        let language = 'auto';
        if (atom.config.get('linter-languagetool.obeyFileLangPattern')) {
            const lanPattern = this.grammarManager.getLanguage(TextEditor);
            if (this.grammarManager.getLanguage(TextEditor)) {
                language = lanPattern[0].replace(/_/, '-');
            }
        }
        
        const editorGrammar = TextEditor.getGrammar()
        const lines = editorGrammar.tokenizeLines(TextEditor.getText())
        const text = []
        
        let field = "text"  
                
        for (let line of lines) {
            for (let part of line) {
                if (this.grammarManager.isIgnored(part.scopes)) {
                    field = "markup"
                } else { 
                    field = "text"
                }
                if (field in (text[text.length-1] || {})) {
                    text[text.length-1][field] = text[text.length-1][field] + part.value
                } else {
                    text.push({[field]: part.value })
                }                         
            }
            text[text.length-1][field] = text[text.length-1][field] + "\n"
                
        }  
        
        const post_data_dict = {
            'language': language,
            'data': JSON.stringify({"annotation": text}),
            'motherTongue': atom.config.get('linter-languagetool.motherTongue')
        };

        if (((atom.config.get('linter-languagetool.preferredVariants')).length > 0) && (language === 'auto')) {
            post_data_dict['preferredVariants'] = atom.config.get('linter-languagetool.preferredVariants').join();
        }
        if ((atom.config.get('linter-languagetool.disabledCategories')).length > 0) {
            post_data_dict['disabledCategories'] = atom.config.get('linter-languagetool.disabledCategories').join();
        }
        if ((atom.config.get('linter-languagetool.disabledRules')).length > 0) {
            post_data_dict['disabledRules'] = atom.config.get('linter-languagetool.disabledRules').join();
        }

        return post_data_dict;
    }

    linterMessagesForData (data, TextEditor) {
        const messages = [];

        const editorPath = TextEditor.getPath();
        const textBuffer = TextEditor.getBuffer();

        const matches = data["matches"];
        for (let match of Array.from(matches)) {
            const offset = match['offset'];
            const length = match['length'];
            var startPos = textBuffer.positionForCharacterIndex(offset);
            var endPos = textBuffer.positionForCharacterIndex(offset + length);

            let description = `*${match['rule']['description']}*\n\n(\`ID: ${match['rule']['id']}\`)`;
            if (match['shortMessage']) {
                description = `${match['message']}\n\n${description}`;
            } else {}

            const replacements = match['replacements'].map(rep =>
                ({
                    title: rep.value,
                    position: [startPos, endPos],
                    replaceWith: rep.value,
                }));
            const message = {
                location: {
                    file: editorPath,
                    position: [startPos, endPos],
                },
                severity: categries_map[match['rule']['category']['id']] || 'error',
                description,
                solutions: replacements,
                excerpt: match['shortMessage'] || match['message']
            };

            if (match['rule']['urls']) {
                message['url'] = match['rule']['urls'][0]['value'];
            }

            messages.push(message);
        }
        return messages;
    }

    lint (TextEditor) {
        
        const provider = this;
        return new Promise( (resolve) => {
            if (!lthelper.ltinfo) {
                // Disable the linter if the server is not responding
                resolve([]);
                return;
            }
            
            const scopes = TextEditor.getRootScopeDescriptor().getScopesArray()
            if (provider.grammarManager.isIgnored(scopes)) {
                resolve([]);
                return;
            }

            const post_data = provider.getPostDataDict(TextEditor);

            const options = {
                method: 'POST',
                uri: lthelper.url,
                form: post_data,
                json: true
            };

            return rp(options)
                .then(function(data) {
                    const messages = provider.linterMessagesForData(data, TextEditor);
                    return resolve(messages);
                })
                .catch(function(err) {
                    console.log(err);
                    atom.notifications.addError("Invalid output received from LanguageTool server", {
                        detail: err.message
                    });
                    return resolve([]);
                });
        });
    }
}

module.exports = LinterProvider
