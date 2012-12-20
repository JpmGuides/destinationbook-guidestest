Ext.define('app.model.GuidePart', {
  extend: 'Ext.data.Model',

  config: {
    fields: [
      'id',
      {name: 'title', type: 'string'},
      {name: 'titleImage', type: 'string'},
      {name: 'headerImage', type: 'string'},
      {name: 'headerImageLegend', type: 'string'},
      {name: 'description', type: 'string'},
      {name: 'content', type: 'string'},
      {name: 'breadcrumbs', type: 'auto'},
      {name: 'maps', type: 'auto'},
      {name: 'order', type: 'int'},
      {name: 'parent_id', type: 'int'}
    ],

    hasOne: {model: 'app.model.GuidePart', name: 'parent', foreignKey: 'parent_id', getterName: 'getParent'},
    hasMany: {model: 'app.model.GuidePart', name: 'parts', foreignKey: 'parent_id'},

    proxy: {
      type: 'ajax',
      url: '../../Library/Caches/Guides/storage.json',
      reader: 'json'
    }
  },

  getGuide: function(callback) {
    var search = function(part) {
      if (Ext.isEmpty(part.get('parent_id'))) {
        callback(part);
      } else {
        part.getParent(function(parent) {
          search(parent);
        });
      }
    }

    search(this);
  }
});

