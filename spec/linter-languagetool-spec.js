"use babel";


describe('The languagetool-linter for AtomLinter', () => {
  const lint = require('../lib/linter-languagetool').provideLinter().lint;
  const lthelper = require('../lib/ltserver-helper')
  
  beforeEach(() => {
    waitsForPromise(() => {
      return atom.packages.activatePackage("linter-languagetool");
    });
    waitsForPromise(() => {
      return new Promise( (resolve) => {
          lthelper.onDidChangeLTInfo(() => {
              resolve()
          });
      });
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

  it('checks the resulting severity for different rule categories (de)', () => {
    waitsForPromise(() => {
      return atom.workspace.open(__dirname + '/test_files/languagetool-cat-test-de.txt').then(editor => {
        return lint(editor).then(messages => {
          expect(messages.length).toEqual(19);

          expect(messages[0].severity).toBeDefined();
          expect(messages[0].severity).toEqual('error');
          expect(messages[1].severity).toBeDefined();
          expect(messages[1].severity).toEqual('info');
          expect(messages[2].severity).toBeDefined();
          expect(messages[2].severity).toEqual('error');
          expect(messages[3].severity).toBeDefined();
          expect(messages[3].severity).toEqual('info');
          expect(messages[4].severity).toBeDefined();
          expect(messages[4].severity).toEqual('error');
          expect(messages[5].severity).toBeDefined();
          expect(messages[5].severity).toEqual('info');
          expect(messages[6].severity).toBeDefined();
          expect(messages[6].severity).toEqual('info');
          expect(messages[7].severity).toBeDefined();
          expect(messages[7].severity).toEqual('error');
          expect(messages[8].severity).toBeDefined();
          expect(messages[8].severity).toEqual('warning');
          expect(messages[9].severity).toBeDefined();
          expect(messages[9].severity).toEqual('info');
          expect(messages[10].severity).toBeDefined();
          expect(messages[10].severity).toEqual('warning');
          expect(messages[11].severity).toBeDefined();
          expect(messages[11].severity).toEqual('error');
          expect(messages[12].severity).toBeDefined();
          expect(messages[12].severity).toEqual('error');
          expect(messages[13].severity).toBeDefined();
          expect(messages[13].severity).toEqual('error');
          expect(messages[14].severity).toBeDefined();
          expect(messages[14].severity).toEqual('warning');
          expect(messages[15].severity).toBeDefined();
          expect(messages[15].severity).toEqual('info');
          expect(messages[16].severity).toBeDefined();
          expect(messages[16].severity).toEqual('warning');
          expect(messages[17].severity).toBeDefined();
          expect(messages[17].severity).toEqual('warning');
          expect(messages[18].severity).toBeDefined();
          expect(messages[18].severity).toEqual('error');
        });
      });
    });
  });

  it('checks the resulting severity for different rule categories (en)', () => {
    waitsForPromise(() => {
      return atom.workspace.open(__dirname + '/test_files/languagetool-cat-test-en.txt').then(editor => {
        return lint(editor).then(messages => {
          expect(messages.length).toEqual(2);
          expect(messages[0].severity).toBeDefined();
          expect(messages[0].severity).toEqual('error');
          expect(messages[1].severity).toBeDefined();
          expect(messages[1].severity).toEqual('info');
        });
      });
    });
  });

  it('does not show errors on disabeld scopes by the linter-spell api', () => {
    waitsForPromise(() => {
      return atom.packages.activatePackage("language-gfm");
    });
    waitsForPromise(() => {
      return atom.workspace.open(__dirname + '/test_files/languagetool-markup-test.md').then(editor => {
        return lint(editor).then(messages => {
          expect(messages.length).toEqual(1);
        });
      });
    });
  });
});
