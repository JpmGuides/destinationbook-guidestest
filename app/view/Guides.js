Ext.define('app.view.Guides', {
  extend: 'Ext.Panel',
  xtype: 'guidescard',
  id: 'guidescard',

  requires: [
    'app.view.GuidesContainer',
    'app.view.CardToolbar'
  ],

  config: {
    layout: 'card',

    items: [
      { xtype: 'guideslist' },
      { xtype: 'guidescontainer' }
    ]
  }
});

