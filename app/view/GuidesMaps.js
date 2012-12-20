Ext.define('app.view.GuidesMaps', {
  extend: 'Ext.List',
  xtype: 'guidesmaps',

  config: {
    cls: 'guides-maps',

    onItemDisclosure: true,
    disableSelection: true,

    fullscreen: true,

    scrollable: {
      direction: 'vertical',
      directionLock: true
    },

    itemTpl: [
      '<div class="custom-list-item-label-text">',
        '<span class="title">{title}</span>',
        '<tpl if="description">',
          '<span class="description">{description}</span>',
        '</tpl>',
      '</div>'
    ]
  },

  getTitle: function() {
    return Ext.isEmpty(this.config.title) ? I18n.t('guides.maps') : this.config.title;
  }
});

