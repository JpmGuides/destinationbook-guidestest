Ext.define('Locale.en', {
  requires: [
    'Lib.I18n'
  ]
}, function() {
  I18n.translations = I18n.translations || {};

  I18n.translations['en'] = {
    button: {
      home: 'Download',
      guides: 'Guides',
      back: 'Back',
      yes: 'Yes',
      no: 'No'
    },

    guides: {
      title: 'Guides',
      maps: 'Maps',
      button: {
        list: 'Guides',
        summary: 'Summary',
        maps: 'Maps'
      }
    },

    sync: {
      help: 'Please sign in in order to<br />download your wallet',
      label: {
        host: '127.0.0.1',
        identifier: '0000.00'
      },
      button: {
        sync: 'Download the guide',
        guide: 'Show guide "{{guide_id}}"'
      },
      progress: {
        start: 'Initializing…',
        download: 'Downloading…',
        save: 'Saving…'
      },
      errors: {
        unknown: {
          title: null,
          message: 'An error has occurred; please try again later.'
        },
        no_guide: {
          title: null,
          message: 'Requested guide doesn\'t exist, please verifiy on server'
        },
        no_connection: {
          title: null,
          message: 'Impossible to connect to the Internet.'
        }
      }
    },

    date: {
      formats: {
        'long': '%B %d, %Y',
        'short': '%b %d'
      },
      day_names: [ 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
      abbr_day_names: [ 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      month_names: [ null, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
      abbr_month_names: [ null, 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    }

  };
});
