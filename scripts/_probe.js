const path = require('path');
const modPath = 'C:/Users/enric/AppData/Roaming/npm/node_modules/@tronsfey/mcp2cli/dist/bake.js';
const bake = require(modPath);
(async () => {
  for (const name of ['ctt-digup', 'digup']) {
    const entry = await bake.getBake(name);
    console.log('---', name, '---');
    console.log(JSON.stringify(entry, null, 2));
    if (entry) console.log('args:', JSON.stringify(bake.configToArgs(entry.config)));
  }
})();
