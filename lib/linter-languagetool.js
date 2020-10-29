'use babel'

import { CompositeDisposable } from 'atom'

module.exports = {
    config: {
        languagetoolServerPath: {
            title: 'URL of the Languagetool server or path to your local languagetool-server.jar',
            description: `Set the URL of your Languagetool server.
It defaults to the public Languagetool server API.
If you give the path to your local languagetool-server.jar,
linter tries to start the local languagetool server and connect to it.`,
            type: 'string',
            default: 'https://languagetool.org/api/',
            order: 1
        },
        configFilePath: {
            title: 'Path to a config file',
            description: 'Path to a configuration file for the LanguageTool server. Can be used to provide the path to the n-gram data to LanugageTool. If given, LanguageTool can detect errors with words that are often confused, like *their* and *there*. See [LanguageTool Wiki](http://wiki.languagetool.org/finding-errors-using-n-gram-data) for more information',
            type: 'string',
            default: ''
        },
        languagetoolServerPort: {
            title: 'Port for local languagetool-server.jar',
            description: 'Sets the port on which the local languagetool server will listen.',
            type: 'number',
            default: 8081
        },
        fallbackToPublicApi: {
            title: 'Fallback to public Languagetool server API',
            description: 'Fallback to public Languagetool server in case the local languagetool-server.jar fails to start up or is missing.',
            type: 'boolean',
            default: false
        },
        grammerScopes: {
            type: 'array',
            description: 'This preference holds a list of grammar scopes languagetool should be applied to.',
            default: ['text.tex.latex', 'source.asciidoc', 'source.gfm', 'text.git-commit', 'text.plain', 'text.plain.null-grammar'],
            items: {
                type: 'string'
            }
        },
        preferredVariants: {
            type: 'array',
            description: 'List of preferred language variants. The language detector used with language=auto can detect e.g. English, but it cannot decide whether British English or American English is used. Thus this parameter can be used to specify the preferred variants like en-GB and de-AT. Only available with language=auto.',
            default: [],
            items: {
                type: 'string'
            }
        },
        disabledCategories: {
            type: 'array',
            description: 'List of LanguageTool rule categories to be disabled.',
            default: [],
            items: {
                type: 'string'
            }
        },
        disabledRules: {
            type: 'array',
            description: 'List of LanguageTool rules to be disabled.',
            default: [],
            items: {
                type: 'string'
            }
        },
        motherTongue: {
            type: 'string',
            description: 'A language code of the user\'s native language, enabling false friends checks for some language pairs.',
            default: require('electron').remote.app.getLocale()
        },
        jvmOptions: {
            type: 'string',
            description: 'JVM options to be passed to the LanguageTool server binary upon startup.',
            default: ''
        },
        lintsOnChange: {
            type: 'boolean',
            description: 'If enabled the linter will run on every change on the file.',
            default: false
        }
    },

    activate() {
        this.subscriptions = new CompositeDisposable();

        const lthelper = require('./ltserver-helper');
        lthelper.init();

        const GrammarManager = require('./grammar-manager');
        this.grammaManager = new GrammarManager();
        this.subscriptions.add(this.grammaManager);


        const GrammarProvider = require('./grammar-provider');
        this.grammarProvider = new GrammarProvider;

        const LinterProvider = require('./linter-provider');
        this.linterProvider = new LinterProvider(this.grammaManager);

        const LTInfoView = require('./lt-status-view');
        return this.ltInfo = new LTInfoView();
    },


    deactivate() {
        const lthelper = require('./ltserver-helper');
        if (lthelper != null) {
            lthelper.destroy();
        }

        if (this.ltInfo != null) {
            this.ltInfo.destroy();
        }
        this.ltInfo = null;

        if (this.statusBarTile != null) {
            this.statusBarTile.destroy();
        }
        this.statusBarTile = null;

        if (this.subscriptions != null) {
            this.subscriptions.dispose();
        }
        return this.subscriptions = null;
    },

    consumeStatusBar(statusBar) {
        return this.statusBarTile = statusBar.addRightTile({
            item: this.ltInfo.element,
            priority: 400
        });
    },

    consumeGrammar(grammars) {
        return this.grammaManager.consumeGrammar(grammars);
    },

    provideGrammar() {
        return this.grammarProvider.provideGrammar();
    },

    provideLinter() {
        return {
            name: 'languagetool',
            scope: 'file',
            lintsOnChange: atom.config.get('linter-languagetool.lintsOnChange'),
            grammarScopes: atom.config.get('linter-languagetool.grammerScopes'),
            lint: (textEditor) => {
                return this.linterProvider.lint(textEditor)
            }
        };
    },

}