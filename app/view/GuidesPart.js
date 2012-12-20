Ext.define('app.view.GuidesPart', {
  extend: 'Ext.Container',
  xtype: 'guidespart',

  config: {
    cls: 'guides-part',

    layout: {
      type: 'vbox',
      pack: 'top'
    },

    fullscreen: true,

    scrollable: {
      direction: 'vertical',
      directionLock: true
    },

    items: [
      {
        xtype: 'panel',
        cls: 'guides-part-header',
        tpl: new Ext.XTemplate(
          '<tpl if="this.hasBreadcrumbs(values.breadcrumbs)">',
            '<span class="guides-breadcrumbs">{[this.displayBreadcrumbs(values.breadcrumbs)]}</span>',
          '</tpl>',
          '<h2>{title}</h2>',
          '<tpl if="headerImage">',
            '<div class="guides-header-image">',
              '<img src="{headerImage}" />',
              '<tpl if="headerImageLegend">',
                '<span class="legend">{headerImageLegend}</span>',
              '</tpl>',
            '</div>',
          '</tpl>',
          {
            hasBreadcrumbs: function(breadcrumbs) {
              return !Ext.isEmpty(this.displayBreadcrumbs(breadcrumbs));
            },
            displayBreadcrumbs: function(breadcrumbs) {
              if (typeof breadcrumbs !== 'undefined') {
                return breadcrumbs.slice(1).join(' > ');
              }
            }
          }
        )
      },
      {
        xtype: 'panel',
        cls: 'guides-part-content'
      },
      {
        xtype: 'guidespartchildrenlist'
      }
    ]
  },

  getTitle: function() {
    return Ext.isEmpty(this.config.title) ? I18n.t('guides.title') : this.config.title;
  },

  updateData : function(part) {
    this.callParent(arguments);

    var guidesStore = Ext.getStore('Guide');

    var header = this.getItems().items[0];
    var content = this.getItems().items[1];
    var children = this.getItems().items[2];

    // set data for header template
    header.setData(part.getData());

    if (!Ext.isEmpty(part.get('headerImage'))) {
      header.addCls('guides-header-image')
    }

    // set content
    if (!Ext.isEmpty(part.get('content'))) {
      content.setHtml(part.get('content'));
    } else {
      content.hide();
    }

    // set children lit
    guidesStore.clearFilter();
    guidesStore.filterBy(function(record) {
      return record.get('parent_id') === part.get('id');
    });

    var childrenData = guidesStore.getData();
    if (!Ext.isEmpty(childrenData.items)) {
      childrenData.items.sort(function(item1, item2) {
        return item1.get('order') > item2.get('order') ? 1 : -1;
      });

      var haveThumbnail = !Ext.isEmpty(Ext.Array.filter(childrenData.items, function(item) {
        return !Ext.isEmpty(item.get('titleImage'));
      }));
      if (haveThumbnail) {
        children.setItemCls('thumbnail');
        children.setOnItemDisclosure(false);
      }

      children.setData(childrenData.items);
    } else {
      children.hide();
    }
  }
});

