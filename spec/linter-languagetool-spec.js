"use babel";

describe('The languagetool-linter for AtomLinter', () => {
  const lint = require('../lib/linter-languagetool').provideLinter().lint;

  beforeEach(() => {
    waitsForPromise(() => {
      return atom.packages.activatePackage("linter-languagetool");
    });
  });

  it('checks the example text taken from the languagetool homepage', () => {
    waitsForPromise(() => {
      return atom.workspace.open(__dirname + '/test_files/languagetool-hp-test.txt').then(editor => {
        return lint(editor).then(messages => {
          expect(messages.length).toEqual(8);

          expect(messages[0].type).toBeDefined();
          expect(messages[0].type).toEqual('Error');
          expect(messages[0].text).toBeDefined();
          expect(messages[0].text).toEqual('This sentence does not start with an uppercase letter');
          expect(messages[0].filePath).toBeDefined();
          expect(messages[0].filePath).toMatch(/.+languagetool-hp-test\.txt$/);
          expect(messages[0].range).toBeDefined();
          expect(messages[0].range.length).toEqual(2);
          expect(messages[0].range).toEqual([[2, 0], [2, 2]]);
        });
      });
    });
  });
});
