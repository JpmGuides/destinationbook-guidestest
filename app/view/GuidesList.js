Ext.define('app.view.GuidesList', {
  extend: 'Ext.Panel',
  xtype: 'guideslist',
  id: 'guideslist',

  requires: [
    'app.view.GuidesPart',
    'app.view.CardToolbar'
  ],

  config: {
    cls: 'guides-list',

    items: [
      {
        docked: 'top',
        xtype: 'titlebar'
      },
      { xtype: 'guidespart' },
      {
        xtype: 'card-toolbar',

        items: [
          {
            text: 'Home',
            iconCls: 'home',
            actionToDo: 'home'
          }
        ]
      }
    ]
  }
});


