Ext.define('app.controller.Sync', {
  extend: 'Ext.app.Controller',

  config: {
    refs: {
      main: 'mainpanel',
      syncCard: 'synccard',
      logsPanel: 'synccard #logsPanel',
      progressBar: '#syncProgressBar'
    },

    control: {
      'synccard': {
        activate: 'resetView'
      },
      '#syncRequestButton': {
        tap: 'launchSync'
      },
      '#showGuidePanelButton': {
        tap: 'showGuidesPanel'
      }
    }
  },

  connectionStates: {},

  refreshLogsDelay: 10000,

  launch: function() {
    this.getSyncCard().setValues(app.guideSync.data);

    Ext.Array.each(this.getSyncCard().getItems().items, function(item) {
      switch(item.config.cls || item.config.name)
      {
        case 'host':
          item.setPlaceHolder(I18n.t('sync.label.host', { locale: I18n.phoneLocale }));
          break;
        case 'identifier':
          item.setPlaceHolder(I18n.t('sync.label.identifier', { locale: I18n.phoneLocale }));
          break;
        case 'sync':
          item.setText(I18n.t('sync.button.sync', { locale: I18n.phoneLocale }));
          break;
        case 'guide':
          item.setText(I18n.t('sync.button.guide', { locale: I18n.phoneLocale, guide_id: '' }));
          break;
      }
    });

    if (typeof Connection !== 'undefined') {
      this.connectionStates[Connection.UNKNOWN]  = 'unknown';
      this.connectionStates[Connection.ETHERNET] = 'network';
      this.connectionStates[Connection.WIFI]     = 'network';
      this.connectionStates[Connection.CELL_2G]  = 'cell';
      this.connectionStates[Connection.CELL_3G]  = 'cell';
      this.connectionStates[Connection.CELL_4G]  = 'cell';
      this.connectionStates[Connection.NONE]     = 'none';
    }

    this.resetView();

    this.refreshLogs();

    this.on('file_downloaded', this._incrementDownloadProgressBar, this);
    app.app.on('go_home', this.showSyncPanel, this);
  },

  resetView: function() {
    this._hideDownloadProgressBar();
  },

  refreshLogs: function() {
    var that = this;
    this.refreshLogs = Ext.Function.createDelayed(this.refreshLogs, this.refreshLogsDelay, this);

    if (Ext.isEmpty(app.guideSync) || Ext.isEmpty(app.guideSync.get('host'))) {
      this.refreshLogs();
      return;
    }

    Ext.Ajax.request({
      url: 'http://' + app.guideSync.get('host') + '/status.json',
      method: 'GET',
      scope: this,
      timeout: 30000,

      // ignore failure
      failure: function(response, request) {
        console.log('Logs refresh failure: ' + response.status + ' - '+ response.statusText);

        if (response.statusText === 'communication failure') {
          that.getLogsPanel().setEmptyText(I18n.t('sync.errors.server_unavailable.message', { locale: I18n.phoneLocale }))
        } else {
          that.getLogsPanel().setEmptyText(I18n.t('sync.errors.logs_unavailable.message', { locale: I18n.phoneLocale }))
        }

        that.getLogsPanel().getStore().removeAll();
        that.refreshLogs();
      },

      // sync guide
      success: function(response) {
        try {
          that.getLogsPanel().getStore().setData(Ext.JSON.decode(response.responseText));
        } catch(err) {
          console.log('Logs refresh failure: ' + err.message);
          that.getLogsPanel().setEmptyText(I18n.t('sync.errors.logs_unavailable.message', { locale: I18n.phoneLocale }))
          that.getLogsPanel().getStore().removeAll();
        }

        that.refreshLogs();
      }
    });
  },

  showGuidesPanel: function(callback) {
    this.getMain().animateActiveItem(this.getMain().getItems().indexOfKey('guidescard'), { type: 'slide', direction: 'left', listeners: {
      animationend: {
        fn: callback,
        scope: this,
        single: true
      }
    }});
  },

  showSyncPanel: function(callback) {
    this.getMain().animateActiveItem(this.getMain().getItems().indexOfKey('synccard'), { type: 'slide', direction: 'right', listeners: {
      animationend: {
        fn: callback,
        scope: this,
        single: true
      }
    }});
  },

  launchSync: function() {
    var connection = (typeof Connection !== 'undefined') ? navigator.connection.type : 'none';

    if (this.connectionStates[connection] !== 'network') {
      Ext.Msg.alert(I18n.t('sync.errors.no_connection.title', { locale: I18n.phoneLocale }), I18n.t('sync.errors.no_connection.message', { locale: I18n.phoneLocale }), Ext.emptyFn);
      return;
    } else {
      this.synchronize();
    }
  },

  synchronize: function() {
    // Display download progress bar
    this._showDownloadProgressBar();

    // reset update status
    this._updateStatus = {
      guides: {
        storage: false,
        images: false,
        maps: false
      }
    };

    // Save travel reference
    app.guideSync.set('synchronized_at', null);
    app.guideSync.set('host', this.getSyncCard().getValues().host);
    app.guideSync.set('identifier', this.getSyncCard().getValues().identifier);
    app.guideSync.save();

    // Sync Guide
    this._updateGuides([{
      id: app.guideSync.get('identifier'),
      url: 'http://' + app.guideSync.get('host') + '/export?guide_id=' + app.guideSync.get('identifier')
    }]);

    // wait on sync callbacks
    var timerStart = new Date();
    var updateStatusToArray = function(o) { return typeof o === 'object' ? Ext.Array.map(Ext.Object.getValues(o), function(o) { return updateStatusToArray(o); }) : o; }
    var timer = function() {
      var finish = !Ext.Array.contains(Ext.Array.flatten(updateStatusToArray(this._updateStatus)), false);

      // continue to wait...
      if (!finish) {
        if ((new Date() - timerStart) > 600000) {
          Ext.Msg.alert(I18n.t('sync.errors.unknown.title', { locale: I18n.phoneLocale }), I18n.t('sync.errors.unknown.message', { locale: I18n.phoneLocale }), Ext.emptyFn);
          this._hideDownloadProgressBar();
        } else {
          Ext.defer(timer, 100, this);
        }

        // finish
      } else {
        // Update sync status
        app.guideSync.set('synchronized_at', new Date());
        app.guideSync.save();

        // Send success event
        app.app.fireEvent('sync_success');

        // Show Guide
        this.showGuidesPanel();
        this._hideDownloadProgressBar();
      }
    }
    timer.apply(this);
  },

  //
  // Guides
  //

  _updateGuides: function(guidesData) {
    var storage = [];

    // set update status for images & maps to false
    this._updateStatus.guides.images = {};
    this._updateStatus.guides.maps = {};
    Ext.Array.map(guidesData, function(guideData) {
      this._updateStatus.guides.images[guideData.id] = false;
      this._updateStatus.guides.maps[guideData.id] = false;
    }, this);

    // start sync of guides
    this._cleanUpDir('Guides', function() {
      this._guidesIDCounter = 1;
      this._downloadGuides(storage, guidesData, function() {
        // write storage
        this._writeStorageFile('Guides', storage, function() {
          this._updateStatus.guides.storage = true;
        }, this);
      }, this);
    }, this);
  },

  _downloadGuides: function(storage, guidesData, callback, scope) {
    var guideData = guidesData.pop();

    Ext.Ajax.request({
      url: guideData.url,
      method: 'GET',
      scope: this,
      timeout: 600000,

      // ignore failure
      failure: function(response, request) {
        Ext.Msg.alert(I18n.t('sync.errors.no_guide.title', { locale: I18n.phoneLocale }), I18n.t('sync.errors.no_guide.message', { locale: I18n.phoneLocale }), Ext.emptyFn);
        this._hideDownloadProgressBar();
      },

      // sync guide
      success: function(response) {
        try {
          var guideData = Ext.JSON.decode(response.responseText);
        } catch(err) {
          console.log(err.message);
          Ext.Msg.alert(I18n.t('sync.errors.unknown.title', { locale: I18n.phoneLocale }), I18n.t('sync.errors.unknown.message', { locale: I18n.phoneLocale }), Ext.emptyFn);
          this._hideDownloadProgressBar();
          return;
        }

        this.filesToDownload = guideData.images.length + guideData.maps.length;
        this.fireEvent('file_downloaded', 0);

        this._updateGuide(storage, guideData);

        callback.apply(scope || this);
      }
    });
  },

  _updateGuide: function(storage, guideData) {
    var guideID  = this._guidesIDCounter++,
    guideDir = 'Guides/' + guideID + '/';
    guideURI = '../../Library/Caches/' + guideDir;

    // add guide to storage
    var guide = {
      id: guideID,
      title: guideData.title || null,
      description: guideData.description || null,
      titleImage: guideData.titleImage ? (guideURI + guideData.titleImage + this._uriSyncTimestamp()) : null,
      headerImage: guideData.headerImage ? (guideURI + guideData.headerImage + this._uriSyncTimestamp()) : null,
      headerImageLegend: guideData.headerImageLegend || null,
      content: null,
      breadcrumbs: [],
      maps: [],
      order: guideData.order || null,
      parent_id: null
    };
    storage.push(guide);

    // add parts to storage
    if (!Ext.isEmpty(guideData.children)) {
      this._updateGuidePartChildren(storage, guideURI, guide, guideData);
    }

    // add maps to guide
    if (!Ext.isEmpty(guideData.maps)) {
      Ext.Array.each(guideData.maps, function(mapData) {
        guide.maps.push({
          title: mapData.title,
          path: guideURI + mapData.path
        });
      }, this);
    }

    // write maps
    this._writeGuideMaps(guideDir, guideData.maps, function() {
      this._updateStatus.guides.maps[guideData.id] = true;

      // write images
      this._writeGuideImages(guideDir, guideData.images, function() {
        this._updateStatus.guides.images[guideData.id] = true;
      }, this);
    }, this);
  },

  _updateGuidePartChildren: function(storage, guideURI, parent, parentData) {
    var order = 1;

    Ext.Array.each(parentData.children, function(childData) {
      var guideID  = this._guidesIDCounter++;

      var breadcrumbs = Ext.Array.clone(parent.breadcrumbs);
      breadcrumbs.push(parent.title);

      var child = {
        id: guideID,
        title: childData.title || null,
        description: childData.description || null,
        titleImage: childData.titleImage ? (guideURI + childData.titleImage + this._uriSyncTimestamp()) : null,
        headerImage: childData.headerImage ? (guideURI + childData.headerImage + this._uriSyncTimestamp()) : null,
        headerImageLegend: childData.headerImageLegend || null,
        content: childData.content ? (childData.content.replace(/(\<img.+?=")\/?/gi, "$1" + guideURI)) : null,
        breadcrumbs: breadcrumbs,
        maps: [],
        order: order,
        parent_id: parent.id
      };

      storage.push(child);

      if (!Ext.isEmpty(childData.children)) {
        this._updateGuidePartChildren(storage, guideURI, child, childData);
      }

      order = order + 1;
    }, this);
  },

  _writeGuideMaps: function(guideDir, mapsData, callback, scope) {
    if (!Ext.isEmpty(mapsData)) {
      this._downloadToFiles(guideDir, mapsData, function() {
        if (callback) {
          callback.apply(scope || this);
        }
      }, this);
    } else if (callback) {
      callback.apply(scope || this);
    }
  },

  _writeGuideImages: function(guideDir, imagesData, callback, scope) {
    if (!Ext.isEmpty(imagesData)) {
      this._downloadToFiles(guideDir, imagesData, function() {
        if (callback) {
          callback.apply(scope || this);
        }
      }, this);
    } else if (callback) {
      callback.apply(scope || this);
    }
  },

  //
  // Utilities
  //

  _downloadToFiles: function(baseDir, files, callback, scope) {
    if (typeof app.fileSystem !== 'undefined') {
      var fileTransfer = new FileTransfer();

      var that = this;
      var downloadFiles = function(files) {
        var file = files.pop();

        if (file && !Ext.isEmpty(file.path) && !Ext.isEmpty(file.url)) {
          that._createDirectory(app.fileSystem.caches, file.path.replace(/^(\.\/|\/)?/gi, baseDir).replace(/\/[^\/]+$/, ''), function(baseDir) {
            fileTransfer.download(
              'http://' + app.guideSync.get('host') + '/' + file.url,
              baseDir.fullPath + '/' + file.path.match(/[^\/]+$/)[0],
              function() {
                that.fireEvent('file_downloaded', 1);
                downloadFiles(files);
              },
              function() {
                that.fireEvent('file_downloaded', 1);
                downloadFiles(files);
              }
            );
          });

        } else if (file) {
          downloadFiles(files);
        } else if (callback) {
          callback.apply(scope || that);
        }
      }
      downloadFiles(Ext.Array.flatten([files]));

    } else if (callback) {
      callback.apply(scope || this);
    }
  },

  _cleanUpDir: function(baseDir, callback, scope) {
    if (typeof app.fileSystem !== 'undefined') {
      app.fileSystem.caches.getDirectory(baseDir, {create: false, exclusive: false}, function(dir) {
        dir.removeRecursively();

        if (callback) {
          callback.apply(scope || this);
        }
      }, function() {
        if (callback) {
          callback.apply(scope || this);
        }
      });
    } else if (callback) {
      callback.apply(scope || this);
    }
  },

  _createDirectory: function(baseDir, directories, callback, scope) {
    if (typeof app.fileSystem !== 'undefined') {
      if (!Ext.isArray(directories)) {
        directories = directories.split('/');
      }

      if (directories.length > 0) {
        var that = this;
        baseDir.getDirectory(directories.shift(), {create: true, exclusive: false}, function(baseDir) {
          that._createDirectory(baseDir, directories, callback, scope);
        });
      } else if (callback) {
        callback.apply(scope || this, [baseDir]);
      }
    } else if (callback) {
      callback.apply(scope || this);
    }
  },

  _writeStorageFile: function(baseDir, storage, callback, scope) {
    var that = this;

    if (typeof app.fileSystem !== 'undefined') {
      app.fileSystem.caches.getDirectory(baseDir, {create: true, exclusive: false}, function(dir) {
        dir.getFile('storage.json', {create: true, exclusive: false}, function(file) {
          file.createWriter(function(writer) {
            if (callback) {
              writer.onwrite = function(event) {
                callback.apply(scope || this);
              };
            }

            writer.write(Ext.JSON.encode(storage));
          });
        });
      });
    } else if (callback) {
      callback.apply(scope || this);
    }
  },

  _showDownloadProgressBar: function() {
    Ext.Array.each(Ext.ComponentQuery.query('#syncRequestButton, #showGuidePanelButton'), function(item) {
      item.hide();
    }, this);

    var progress = this.getProgressBar();
    progress.element.query('.progress')[0].style.width = '0px';
    progress.element.query('.message')[0].innerText = I18n.t('sync.progress.start', { locale: I18n.phoneLocale });
    progress.show();
    this.filesDownloaded = 0;
  },

  _hideDownloadProgressBar: function() {
    Ext.Array.each(Ext.ComponentQuery.query('#syncRequestButton'), function(item) {
      item.show();
    }, this);

    Ext.Array.each(Ext.ComponentQuery.query('#showGuidePanelButton'), function(item) {
      if (app.travel.isSynchronized()) {
        Ext.Array.each(this.getSyncCard().getItems().items, function(item) {
          switch(item.config.cls || item.config.name)
          {
            case 'guide':
              item.setText(I18n.t('sync.button.guide', { locale: I18n.phoneLocale, guide_id: app.guideSync.get('identifier') }));
            break;
          }
        });
        item.show();
      } else {
        item.hide();
      }
    }, this);

    Ext.Array.each(Ext.ComponentQuery.query('#syncProgressBar'), function(item) {
      item.hide();
      item.element.query('.progress')[0].style.width = '0px';
    }, this);
  },

  _incrementDownloadProgressBar: function(incr) {
    var progress = this.getProgressBar();
    var maxWidth = progress.innerElement.dom.offsetWidth;

    // set download status message
    progress.element.query('.message')[0].innerText = I18n.t('sync.progress.download', { locale: I18n.phoneLocale });

    // set progress bar width to correct height
    this.filesDownloaded += incr;
    if (this.filesDownloaded === 0 && this.filesToDownload > 0) {
      progress.element.query('.progress')[0].style.width = '0px';
    } else if (this.filesDownloaded >= this.filesToDownload) {
      progress.element.query('.message')[0].innerText = I18n.t('sync.progress.save', { locale: I18n.phoneLocale });
      progress.element.query('.progress')[0].style.width = maxWidth + 'px';
    } else {
      progress.element.query('.progress')[0].style.width = Math.round(this.filesDownloaded / this.filesToDownload * maxWidth) + 'px';
    }
  },

  _syncTimestamp: function() {
    return new Date().getTime().toString();
  },

  _uriSyncTimestamp: function() {
    return '?' + this._syncTimestamp();
  }
});

