Ext.define('app.view.Sync', {
  extend: 'Ext.form.Panel',
  xtype: 'synccard',
  id: 'synccard',

  config: {
    title: 'Settings',

    layout: 'vbox',

    fullscreen: true,

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
        xtype: 'button',
        cls: 'spacer',
        html: '&nbsp;'
      }, {
        xtype: 'list',
        cls: 'logs',
        id: 'logsPanel',

        // layout: 'fit',
        flex: 1,

        scrollable: {
          direction: 'vertical',
          directionLock: true
        },

        pressedCls: null,
        disableSelection: true,

        store: {
          fields: ['time', 'guide_id', 'status', 'message'],

          sorters: [
            {
              property : 'time',
              direction: 'DESC'
            }
          ],

          data: []
        },

        emptyText: 'logs is unavailable...',

        itemTpl: new Ext.XTemplate(
          '<div class="guide">',
            '<span class="guide_id">{guide_id}</span>',
            '<span class="time">{[this.displayTime(values.time)]}</span>',
          '</div>',
          '<tpl if="status != \'successfull\' ">',
            '<div class="error">{message}</div>',
          '</tpl>',
          {
            displayTime: function(time) {
              return I18n.l('time.formats.long', parseInt(time) * 1000);
            }
          }
        )
      }
    ]
  }
});
