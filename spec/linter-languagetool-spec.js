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

  it('checks the example text taken from the languagetool homepage with variant en-GB', () => {
    waitsForPromise(() => {
      atom.config.set('linter-languagetool.preferredVariants',['en-GB'])
      return atom.workspace.open(__dirname + '/test_files/languagetool-hp-test.txt').then(editor => {
        return lint(editor).then(messages => {
          expect(messages.length).toEqual(9);

          expect(messages[0].severity).toBeDefined();
          expect(messages[0].severity).toEqual('error');
          expect(messages[0].excerpt).toBeDefined();
          expect(messages[0].excerpt).toEqual('Spelling mistake');
          expect(messages[0].location.file).toBeDefined();
          expect(messages[0].location.file).toMatch(/.+languagetool-hp-test\.txt$/);
          expect(messages[0].location.position).toBeDefined();
          expect(messages[0].location.position.length).toEqual(2);
          expect(messages[0].location.position).toEqual([[1, 10], [1, 17]]);
        });
      });
    });
  });

  it('checks an mixed language example text taken from the languagetool homepage with TeX magic comment to define the language', () => {
    waitsForPromise(() => {
      return atom.workspace.open(__dirname + '/test_files/languagetool-mc-test.txt').then(editor => {
        return lint(editor).then(messages => {
          expect(messages.length).toEqual(22);

          expect(messages[21].severity).toBeDefined();
          expect(messages[21].severity).toEqual('error');
          expect(messages[21].excerpt).toBeDefined();
          expect(messages[21].excerpt).toEqual('Rechtschreibfehler');
          expect(messages[21].location.file).toBeDefined();
          expect(messages[21].location.file).toMatch(/.+languagetool-mc-test\.txt$/);
          expect(messages[21].location.position).toBeDefined();
          expect(messages[21].location.position.length).toEqual(2);
          expect(messages[21].location.position).toEqual([[6, 0], [6, 6]]);
        });
      });
    });
  });

});
