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

          expect(messages[0].severity).toBeDefined();
          expect(messages[0].severity).toEqual('error');
          expect(messages[0].excerpt).toBeDefined();
          expect(messages[0].excerpt).toEqual('This sentence does not start with an uppercase letter');
          expect(messages[0].location.file).toBeDefined();
          expect(messages[0].location.file).toMatch(/.+languagetool-hp-test\.txt$/);
          expect(messages[0].location.position).toBeDefined();
          expect(messages[0].location.position.length).toEqual(2);
          expect(messages[0].location.position).toEqual([[2, 0], [2, 2]]);
        });
      });
    });
  });
});
