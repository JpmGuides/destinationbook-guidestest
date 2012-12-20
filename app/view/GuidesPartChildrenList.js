Ext.define('app.view.GuidesPartChildrenList', {
  extend: 'Ext.List',
  xtype: 'guidespartchildrenlist',

  config: {
    cls: 'guides-part-children-list',
    title: 'Guides',

    onItemDisclosure: true,
    disableSelection: true,

    scrollable: false,

    store: {
      fields: ['title', 'description', 'titleImage'],
    },

    itemTpl: [
      '<div class="custom-list-item-label-text">',
        '<span class="title">{title}</span>',
        '<tpl if="description">',
          '<span class="description">{description}</span>',
        '</tpl>',
      '</div>',
      '<tpl if="titleImage">',
        '<div class="custom-list-item-label-image">',
          '<img src="{titleImage}" />',
        '</div>',
      '</tpl>'
    ]
  },
});

