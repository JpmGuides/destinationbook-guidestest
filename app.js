//<debug>
Ext.Loader.setPath({
  'Ext': 'sdk/src',
  'Lib': 'lib',
  'Locale': 'resources/locales'
});
//</debug>

Ext.application({
  name: 'app',

  requires: [
    'Ext.MessageBox',
    'Ext.DateExtras',
    'Ext.data.JsonP',
    'Lib.I18n',
    'Locale.en'
  ],

  controllers: ['Sync', 'Guides'],
  views: ['Main'],
  stores: ['Guide'],
  models: ['GuideSync', 'GuidePart'],

  launch: function() {
    // Initialize filesystem
    if (typeof LocalFileSystem != 'undefined') {
      window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, function(fileSystem) {
        app.fileSystem = fileSystem;
        app.fileSystem.documents = app.fileSystem.root
        app.fileSystem.root.getDirectory('../Library/Caches/', {create: false, exclusive: false}, function(caches) {
          app.fileSystem.caches = caches;
        });
      }, function(e) {
        console.log(e.target.error.code);
      });
    }

    // initialize I18n
    I18n.fallbacks = true;
    I18n.locale = I18n.phoneLocale = I18n.defaultLocale = 'en';

    // message box buttons translation
    Ext.apply(Ext.MessageBox, {
      YES: { text: I18n.t('button.yes', { locale: I18n.phoneLocale }), itemId: 'yes', ui: 'action' }
    });
    Ext.apply(Ext.MessageBox, {
      NO: { text: I18n.t('button.no', { locale: I18n.phoneLocale }), itemId: 'no' }
    });
    Ext.apply(Ext.MessageBox, {
      YESNO: [Ext.MessageBox.NO, Ext.MessageBox.YES]
    });

    // initialize current travel
    this._initGuideSync(function() {
      // initialite main view
      this._initMainView();

      // hide splashscreen
      this.hideSplashScreen();
    }, this);
  },

  _initGuideSync: function(callback, scope) {
    app.model.GuideSync.load(1, {
      success: function(guideSync) {
        app.travel = app.guideSync = guideSync;

        if (callback) {
          callback.apply(scope || this);
        }
      },
      failure: function() {
        app.travel = app.guideSync = Ext.create('app.model.GuideSync', {
          id: 1,
          locale: I18n.phoneLocale,
          'synchronized': {
            guides: false
          },
          synchronized_at: null
        });
        app.guideSync.save();

        if (callback) {
          callback.apply(scope || this);
        }
      },
      scope: this
    });
  },

  _initMainView: function() {
    // Initialize the main view
    var main = Ext.create('app.view.Main');
    main.setActiveItem(main.getItems().indexOfKey('synccard'));

    // Show main view
    Ext.Viewport.add(main);
  },

  onUpdated: function() {
    Ext.Msg.confirm(
      "Application Update",
      "This application has just successfully been updated to the latest version. Reload now?",
      function() {
        window.location.reload();
      }
    );
  },

  hideSplashScreen: function() {
    if (cordovaReady) {
      Ext.defer(function() {
        navigator.splashscreen.hide();
      }, 1000, this);
    } else {
      Ext.defer(this.hideSplashScreen, 200, this);
    }
  }
});

var cordovaReady = false;
document.addEventListener('deviceready', function() {
  cordovaReady = true;
}, false)
