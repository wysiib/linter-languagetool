"use babel";
const { spawn } = require('child_process');
const lthelper = require('../lib/ltserver-helper')

describe('The LanguageServer Helper Module', () => {
 
  beforeEach(() => {
    waitsForPromise(() => {
      return lthelper.init()
    });
  });
  
  afterEach(() => {
      lthelper.destroy()
  });
  
  it('connects by default to the public server', () => {
    expect(lthelper.url).toEqual('https://languagetool.org/api/v2/check');
    expect(lthelper.ltinfo).toBeDefined();
  });
});

// Test the local servers only on mac os because there we can install langugeetool
// on travis
if (process.platform === 'darwin') {
  describe('When the local jar is given', () => {
    
    beforeEach(() => {
      atom.config.set('linter-languagetool.languagetoolServerPath','/usr/local/Cellar/languagetool/3.9/libexec/languagetool-server.jar')
      waitsForPromise(() => {
        return lthelper.init()
      });
    });
    
    afterEach(() => {
        lthelper.destroy()
    });
          
    it('it starts the service', () => {
      expect(lthelper.ltserver).toBeDefined();
      expect(lthelper.ltserver.process).toBeDefined();
      expect(lthelper.url).toEqual('http://localhost:8081/v2/check');
      expect(lthelper.ltinfo).toBeDefined();
    });    
  });
  
  describe('When the local jar and port is given', () => {
    
    beforeEach(() => {
      atom.config.set('linter-languagetool.languagetoolServerPath','/usr/local/Cellar/languagetool/3.9/libexec/languagetool-server.jar')
      atom.config.set('linter-languagetool.languagetoolServerPort',8085)
      waitsForPromise(() => {
        return lthelper.init()
      });
    });
    
    afterEach(() => {
        lthelper.destroy()
    });
          
    it('it starts the service on the given port', () => {
      expect(lthelper.ltserver).toBeDefined();
      expect(lthelper.ltserver.process).toBeDefined();
      expect(lthelper.url).toEqual('http://localhost:8085/v2/check');
      expect(lthelper.ltinfo).toBeDefined();
    });    
  });
  
  describe('When the local path not exists', () => {
    
    beforeEach(() => {
      atom.config.set('linter-languagetool.languagetoolServerPath','/languagetool-server.jar')
      waitsForPromise(() => {
        return lthelper.init();
      });
    });
    
    afterEach(() => {
        lthelper.destroy();
    });
          
    it('it shows a warning and uses the public server', () => {
      noti = atom.notifications.getNotifications();
      expect(noti[0].type).toEqual("warning");    
      expect(lthelper.url).toEqual('https://languagetool.org/api/v2/check');
      expect(lthelper.ltinfo).toBeDefined();
    });    
  });
  
  describe('When a custom url is given', () => {
  let process;          
    
    beforeEach(() => {
      waitsForPromise(() => {
        return new Promise( (resolve) => {
          process = spawn('/usr/local/bin/languagetool-server',
            ['-p','8082']);
          process.stdout.on('data', (data) => {
              if (/Server started/.test(data)) {
                resolve()
              }
          });
        });
      });
      
      atom.config.set('linter-languagetool.languagetoolServerPath','http://localhost:8082')
      waitsForPromise(() => {
        return lthelper.init()
      });
    });
    
    afterEach(() => {
        lthelper.destroy()
        process.kill();
    });
          
    it('it uses the given url', () => {
      expect(lthelper.url).toEqual('http://localhost:8082/v2/check');
      expect(lthelper.ltinfo).toBeDefined();
    });    
  });
  
  describe('When the custom url is not responding', () => {
          
    beforeEach(() => { 
      atom.config.set('linter-languagetool.languagetoolServerPath','http://localhost:8082')
      waitsForPromise(() => {
        return lthelper.init()
      });
    });
    
    afterEach(() => {
        lthelper.destroy()
    });
          
    it('it shows a warning and uses the public server', () => {
      noti = atom.notifications.getNotifications();
      expect(noti[0].type).toEqual("warning");    
      expect(lthelper.url).toEqual('https://languagetool.org/api/v2/check');
      expect(lthelper.ltinfo).toBeDefined();
    });     
  });
}
  
