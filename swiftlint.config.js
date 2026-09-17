const path = require('node:path');
const config = require('@ionic/swiftlint-config');

module.exports = {
  ...config,
  excluded: [path.join(__dirname, '.build'), path.join(__dirname, 'node_modules'), path.join(__dirname, 'example-app')],
  identifier_name: {
    min_length: 3,
    excluded: ['t0', 't1', 't2', 't3'],
  },
};
