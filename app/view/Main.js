Ext.define("app.view.Main", {
  extend: 'Ext.Panel',
  xtype: 'mainpanel',
  id: 'mainpanel',

  requires: [
    'app.view.Sync',
    'app.view.Guides'
  ],

  config: {
    layout: 'card',

    items: [
      { xtype: 'synccard' },
      { xtype: 'guidescard' }
    ]
  }

});
