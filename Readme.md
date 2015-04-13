# shortcuts

manages keyboard shortcuts in browser.

# usage

```js
var shortcuts = new Shortcuts({
  foo: [
    { name: 'bar', binding: [ ['ctrl+x'], ['command+x'] ]}
  ]
});
shorcuts.on('key:foo', function () { })
```

See [keyconfig](https://github.com/tetsuo/keyconfig) for spec.

# api

# ctor(defaults={})

Returns an `events.EventEmitter`.

# .get(collectionName, modelName)
# .update(collectionName, modelName, value, silent)
# .getCollisions(collectionName)

# events

# `key:collectionName`
# `change`

# license

mit