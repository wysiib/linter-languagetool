linter-languagetool
=========================

This linter plugin for [Linter](https://github.com/AtomLinter/Linter) uses [languagetool](https://languagetool.org) for spell and grammar checking.

## Installation
Call
```
$ apm install linter-languagetool
```
from the command line or install linter-languagetool using the preferences.

You do not need to worry about dependencies as they will be automatically installed by apm.

## Preferences
- You can use a local languagetool server by setting the preference to the path of languagetool-server.jar
The server will automatically be started. Note that you need to use languagetool version >=3.6 for the local server.
- Additionally, you can store your mother tongue to enable languagetool's checks for false friends and common mistakes.
- For improved error detection, download and install the n-gram data as outlined [here](http://wiki.languagetool.org/finding-errors-using-n-gram-data). The Atom plugin provides a preference to pass the n-gram path to the languagetool server.

## Contributing
Feel free to provide feature requests or bug reports using the link above.

Code contributions are greatly appreciated. Please fork this repository and open a
pull request.

Please note that modifications should follow these coding guidelines:

- Indent is 2 spaces.
- Code should pass coffeelint linter. This is automatically verified by travis-ci.
