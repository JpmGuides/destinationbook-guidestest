Ext.define('app.model.GuideSync', {
  extend: 'Ext.data.Model',

  config: {
    fields: [
      'id',
      { name: 'host', type: 'string' },
      { name: 'identifier', type: 'string' },
      { name: 'locale', type: 'string' },
      { name: 'synchronized_at', type: 'auto' },
    ],

    proxy: {
      type: 'localstorage',
      id: 'travel-model'
    }
  },

  isSynchronized: function(key) {
    return !Ext.isEmpty(this.get('synchronized_at'));
  }
});
