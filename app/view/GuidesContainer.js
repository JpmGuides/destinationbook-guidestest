Ext.define('app.view.GuidesContainer', {
  extend: 'Ext.NavigationView',
  xtype: 'guidescontainer',
  id: 'guidescontainer',

  requires: [
    'app.view.GuidesPart',
    'app.view.CardToolbar'
  ],

  config: {
    cls: 'guides-container',

    items: [
      {
        xtype: 'card-toolbar',

        items: [
          {
            text: 'Home',
            iconCls: 'home',
            actionToDo: 'home'
          },
          {
            text: 'Guides',
            iconCls: 'guides',
            actionToDo: 'list'
          },
          {
            text: 'Summary',
            iconCls: 'list',
            actionToDo: 'summary'
          },
          {
            text: 'Maps',
            iconCls: 'maps',
            actionToDo: 'maps'
          }
        ]
      }
    ]
  }
});


