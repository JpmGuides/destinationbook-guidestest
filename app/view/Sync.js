Ext.define('app.view.Sync', {
  extend: 'Ext.form.Panel',
  xtype: 'synccard',
  id: 'synccard',

  config: {
    title: 'Settings',

    layout: 'vbox',

    scrollable: false,

    items: [
      {
        xtype: 'textfield',
        name: 'host',
        cls: 'host',

        autoComplete: false,
        autoCorrect: false,
        autoCapitalize: false

      }, {
        xtype: 'textfield',
        name: 'identifier',
        cls: 'identifier',

        autoComplete: false,
        autoCorrect: false,
        autoCapitalize: false
      }, {
        xtype: 'button',
        cls: 'sync',
        id: 'syncRequestButton'
      }, {
        xtype: 'button',
        cls: 'progress-bar',
        id: 'syncProgressBar',
        html: '<div class="progress"></div><div class="message">Downloading&hellip;</div>',
        hidden: true
      }, {
        xtype: 'button',
        cls: 'guide',
        id: 'showGuidePanelButton',

        hidden: true
      }, {
        xtype: 'panel',
        cls: 'logs'
      }
    ]
  }
});
