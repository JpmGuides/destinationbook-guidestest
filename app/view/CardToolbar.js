Ext.define('app.view.CardToolbar', {
  extend: 'Ext.Panel',
  xtype: 'card-toolbar',

  config: {
    docked: 'bottom',
    cls: 'card-toolbar',

    layout: {
      type: 'hbox'
    },

    defaults: {
      xtype: 'button',
      baseCls: 'card-toolbar-button'
    }
  },

  updateTexts: function(i18nScope) {
    Ext.Array.each(this.getItems().items, function(item) {
      item.setText(I18n.t(i18nScope + '.button.' + item.config.actionToDo, { defaultValue: I18n.t('button.' + item.config.actionToDo) }));
    });
  }
});
