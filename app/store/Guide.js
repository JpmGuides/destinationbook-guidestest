Ext.define('app.store.Guide', {
  extend: 'Ext.data.Store',

  config: {
    model: 'app.model.GuidePart',

    autoload: true,
    autosync: false
  }
});
