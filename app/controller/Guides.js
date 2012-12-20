Ext.define('app.controller.Guides', {
  extend: 'Ext.app.Controller',

  openned: [],
  guidesCount: 0,

  requires: [
    'app.store.Guide',
    'app.view.Guides',
    'app.view.GuidesList',
    'app.view.GuidesContainer',
    'app.view.GuidesPart',
    'app.view.GuidesPartChildrenList',
    'app.view.GuidesMaps'
  ],

  config: {
    refs: {
      guidesCard: 'guidescard',
      guidesList: 'guidescard guideslist',
      guidesContainer: 'guidescard guidescontainer'
    },

    control: {
      'guidescard guidescontainer': {
        pop: 'onPopFromView'
      },
      'guidescard card-toolbar button': {
        tap: 'onTapToolbarButton'
      },
      'guidespartchildrenlist': {
        itemtap: 'onTapGuidesPartListItem'
      },
      'guidesmaps': {
        itemtap: 'onTapGuidesMapsItem'
      }
    }
  },

  launch: function(app) {
    this._initView();
    this.loadStore();

    app.on('sync_success', this._initView, this);
    app.on('sync_success', this.loadStore, this);
  },

  _initView: function() {
    this.getGuidesContainer().getNavigationBar().setDefaultBackButtonText(I18n.t('button.back'));
  },

  loadStore: function() {
    if (!app.travel.isSynchronized('guides')) {
      return;
    }

    // load guides
    var guidesStore = Ext.getStore('Guide');
    guidesStore.load(function(records) {
      // get guides
      var guides = Ext.Array.filter(records, function(record) {
        return Ext.isEmpty(record.get('parent_id'));
      }).sort(function(item1, item2) {
        return item1.get('order') > item2.get('order') ? 1 : -1;
      });

      this.guidesCount = guides.length;

      this.getGuidesContainer().removeAll();
      this.getGuidesContainer().getNavigationBar().backButtonStack = [];

      // display multiple guides
      if (this.guidesCount > 1) {
        var listView = Ext.create('app.view.GuidesPartChildrenList');
        listView.setItemCls('thumbnail');
        listView.setData(guides);
        this.getGuidesList().query('titlebar')[0].setTitle(I18n.t('guides.title'));
        this.getGuidesList().query('card-toolbar')[0].updateTexts('guides');
        this.getGuidesList().setItems(listView);

        this.getGuidesCard().setActiveItem(this.getGuidesList());
      // display one guide
      } else {
        var view = Ext.create('app.view.GuidesPart');
        this.activeGuide = guides[0];
        view.setData(guides[0]);

        this.getGuidesContainer().setItems(view);
        this.getGuidesContainer().query('card-toolbar')[0].updateTexts('guides');
        this._toggleButtons(this.getGuidesContainer().getItems());
        this.getGuidesCard().setActiveItem(this.getGuidesContainer());
      }
    }, this);
  },

  resetGuide: function() {
    this.getGuidesContainer().reset();
    this.openned.splice(0);
  },

  showMaps: function() {
    var maps = this.activeGuide.get('maps');

    if (Ext.Array.contains(this.openned, maps)) {
      if (this.openned[this.openned.length - 1] !== maps) {
        this.getGuidesContainer().pop();
      }
      return;
    } else {
      this.openned.push(maps);
    }

    this.getGuidesContainer().push({
      xtype: 'guidesmaps',

      fullscreen: true,

      scrollable: {
        direction: 'vertical',
        directionLock: true
      },

      data: maps
    });
  },

  showGuidesList: function() {
    var that = this;

    this.getGuidesCard().animateActiveItem(this.getGuidesList(), { type: 'flip', duration: 300, listeners: {
      animationend: function() {
        that.resetGuide();
      }
    }});
  },

  onTapGuidesPartListItem: function(list, index, item, part) {
    if (Ext.Array.contains(this.openned, part)) {
      return;
    } else {
      this.openned.push(part);
    }

    if (Ext.isEmpty(part.get('parent_id'))) {
      this.activeGuide = part;

      this.getGuidesContainer().removeAll();
      this.getGuidesContainer().getNavigationBar().backButtonStack = [];

      this.getGuidesContainer().setItems(Ext.create('app.view.GuidesPart', {
        title: I18n.t('guides.title'),
        data: part
      }));

      this.getGuidesContainer().query('card-toolbar')[0].updateTexts('guides');
      this._toggleButtons(this.getGuidesContainer().getItems());

      this.getGuidesCard().animateActiveItem(this.getGuidesContainer(), { type: 'flip', duration: 300 });
    } else {
      this.getGuidesContainer().push({
        xtype: 'guidespart',
        title: this.activeGuide.get('title'),

        data: part
      });
    }
  },

  onTapGuidesMapsItem: function(list, index, item, map) {
    if (Ext.Array.contains(this.openned, map)) {
      return;
    } else {
      this.openned.push(map);
    }

    this.getGuidesContainer().push({
      xtype: 'panel',
      title: map.get('title'),
      cls: 'guides-map',

      fullscreen: true,

      scrollable: {
        direction: 'vertical',
        directionLock: true
      },

      listeners: {
        painted : function(component) {
          var el  = component.element,
              img = el.down('img');

          el.addCls('image-loader');
          img.dom.addEventListener('load', function() {
            el.removeCls('image-loader');
          });
        }
      },

      html: [
        '<img src="' + map.get('path') + '" />'
      ]
    });
  },

  onPopFromView: function() {
    this.openned.pop();
  },

  onTapToolbarButton: function(button) {
    var actionToDo = button.config.actionToDo;

    // go home
    if (actionToDo === 'home') {
      app.app.fireEvent('go_home');
    } else if (actionToDo === 'list') {
      this.showGuidesList();
    } else if (actionToDo === 'summary') {
      this.resetGuide();
    } else if (actionToDo === 'maps') {
      this.showMaps();
    }
  },

  _toggleButtons: function(items) {
    items.eachKey(function(key, el) {
      if (key.match(/^ext-card-toolbar-\d+/)) {
        el.getItems().eachKey(function(key, el) {
          if (el.config.actionToDo === 'maps') {
            if (!Ext.isEmpty(this.activeGuide.get('maps'))) {
              el.show();
            } else {
              el.hide();
            }
          }

          if (el.config.actionToDo === 'list') {
            if (this.guidesCount > 1) {
              el.show();
            } else {
              el.hide();
            }
          }
        }, this)
      }
    }, this);
  }
});

