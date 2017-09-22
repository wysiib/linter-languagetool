## 0.6.1
* add preference for disabled rules

## 0.6.0
* replace n-gram data path option by config file option (see issue #17)

## 0.5.2
* improved error handling

## 0.5.1
* report answer from LanguageTool server in case JSON parsing fails

## 0.5.0
* avoid starting a publicly reachable languagetool server
* add preference for n-gram path (thanks @hesstobi)
* severity based on languagetool rules for German and English (thanks @hesstobi)
* add preference for disabled categories

## 0.4.4
* intermediate version fixing git tags / apm published version

## 0.4.3
* add preference for "language variants" (again, credits go to @hesstobi)

## 0.4.2
* add preference for "lint on change" (again, credits go to @hesstobi)

## 0.4.1
* disable lints on change for performance reasons
* changes needed for languagetool v3.6

## 0.4.0
* linter v2 api
* add preference for mother tongue (thanks @hesstobi)
* support suggesting changes (thanks @hesstobi)

## 0.3.2
* fix communication with languagetool server when checking large files

## 0.3.1
* fix port number of public language tool server

## 0.3.0
* add ability to use local server instead of api
* add preference to provide the grammar scopes languagetool should be applied to

## 0.2.0
* fix position reported by linter

## 0.1.0 - First Release
* initial release of basic spell and grammar checker using languagetool
