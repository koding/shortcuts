Shortcuts = require '../index'
assert = require 'assert'

describe 'Shortcuts', ->

  describe 'get', ->

    s = new Shortcuts
      x: [
        { name: 'foo' }
      ]
      y: [
        { name: 'bar' }
        { name: 'baz' }
      ]

    it 'should get by collection', ->

      assert.equal s.get('x').name, 'x'
      assert.equal s.get('y').name, 'y'

    it 'should get my collection/model', ->

      z = s.get 'z'
      assert.equal s.get('y', 'baz').name, 'baz'
      assert.equal z, undefined

      assert.doesNotThrow -> s.get('z', 'qux')


  describe 'binding', ->

    it 'should update num of listeners', ->

      s = new Shortcuts
        x: []
        y: []

      assert.equal s._numListeners.x, 0
      assert.equal s._numListeners.y, 0

      s.on 'key:x', ->
      assert.equal s._numListeners.x, 1
      assert.equal s._numListeners.y, 0

      s.once 'key:x', ->
      assert.equal s._numListeners.x, 2

      s.removeAllListeners 'key:x'
      assert.equal s._numListeners.x, 0

    it 'removeAllListeners should always expect a type', ->

      s = new Shortcuts
      assert.throws s.removeAllListeners

    it 'should bind/unbind keys', ->

      s = new Shortcuts
        x: [
          { name: 'a', binding: [ ['z'], ['x', 'y'] ] },
          { name: 'b', binding: [ null, ['a+b'] ] }
        ],
        y: [
          { name: 'c', binding: [ null, ['a+b'] ] }
        ]

      times = 0
      cb = (n, e) ->
        if times is 0
          if n is 'x'
            assert.equal e.sequence, 'y'
            assert.equal e.collection.name, 'x'
            assert.equal e.model.name, 'a'
          if n is 'y'
            assert.equal e.sequence, 'a+b'
            assert.equal e.collection.name, 'y'
            assert.equal e.model.name, 'c'
        times++

      cbx = cb.bind cb, 'x'
      cby = cb.bind cb, 'y'

      s.on 'key:x', cbx
      assert.equal Object.keys(s._listeners).length, 1

      s.on 'key:y', cby
      assert.equal Object.keys(s._listeners).length, 2

      assert.equal s._listeners.x.a.length, 2
      assert.equal s._listeners.x.a[0].sequence, 'x'

      Mousetrap.trigger 'y'
      Mousetrap.trigger 'y'
      assert.equal times, 2

      Mousetrap.trigger 'a+b'
      assert.equal times, 3

      s.removeListener 'key:x', cbx

      assert.equal Object.keys(s._listeners).length, 1

      Mousetrap.trigger 'y'
      assert.equal times, 3

      Mousetrap.trigger 'a+b'
      assert.equal times, 3

      s.removeAllListeners 'key:y'
      Mousetrap.trigger 'a+b'
      assert.equal times, 3

      assert.equal Object.keys(s._listeners).length, 0

      times = 0

      assert.equal s._numListeners.x, 0

      s.once 'key:x', cbx
      assert.equal s._numListeners.x, 0
      assert.equal Object.keys(s._listeners).length, 1

      Mousetrap.trigger 'y'

      assert.equal times, 1
      assert.equal Object.keys(s._listeners).length, 1

      Mousetrap.trigger 'y'
      assert.equal times, 1

    it 'should not bind disabled models', (done) ->

      s = new Shortcuts
        x: [
          name: 'foo'
          binding: [ null, [ 'f+v' ] ]
          options: enabled: false
        ]

      times = 0

      cb = (e) ->
        assert.equal e.sequence, 'j+g'
        if ++times is 2
          done()

      s.on 'key:x', cb

      Mousetrap.trigger 'f+v'
      s.update 'x', 'foo', { binding: [ null, [ 'j+g' ]], options: enabled: yes }
      Mousetrap.trigger 'j+g'
      Mousetrap.trigger 'f+v'
      Mousetrap.trigger 'j+g'


  describe 'collisions', ->

    it 'should return colliding bindings for this platform', ->

      s = new Shortcuts
        y: [
          { name: 'a', binding: [ null, [ 'z' ] ] }
          { name: 'b', binding: [ null, [ 'z' ] ] }
          { name: 'c', binding: [ null, [ 'x' ] ] }
        ]

      collisions = s.getCollisions 'y'

      assert.equal collisions[0].length, 2
      assert.equal collisions[0][0].name, 'a'
      assert.equal collisions[0][1].name, 'b'


  describe 'update', ->

    it 'should update existing models and emit change', (done) ->

      s = new Shortcuts
        x: [
          name: 'foo'
          binding: [ null, [ 'z' ] ]
        ]

      model = s.get('x', 'foo')
      assert.deepEqual model.getMacKeys(), ['z']

      s.once 'change', (collection, model) ->
        assert.equal collection.name, 'x'
        assert.equal model.name, 'foo'
        assert.deepEqual model.getMacKeys(), ['y']
        done()

      changed = s.update 'x', 'foo', binding: [ null, [ 'y' ] ]
      assert.deepEqual changed, model

    it 'should reset key bindings', (done) ->

      s = new Shortcuts
        x: [
          name: 'foo'
          binding: [ null, [ 'z+s' ] ]
        ]

      times = 0

      cb = (e) ->
        switch ++times
          when 1
            assert.equal e.sequence, 'z+s'
          when 2
            assert.equal e.sequence, 'y+f'
            done()

      s.on 'key:x', cb

      Mousetrap.trigger 'z+s'

      s.once 'change', ->
        Mousetrap.trigger 'z+s'
        Mousetrap.trigger 'y+f'

      s.update 'x', 'foo', binding: [ null, [ 'y+f' ] ]

    it 'should not mess up unchanged bindings', (done) ->

      s = new Shortcuts
        x: [
          name: 'foo'
          binding: [ null, [ 'd+u', 'h+r' ] ]
        ]

      times = 0

      cb = (e) ->
        switch ++times
          when 1
            assert.equal e.sequence, 'd+u'
          when 2
            assert.equal e.sequence, 'h+r'
          when 3
            assert.equal e.sequence, 'h+r'
          when 4
            assert.equal e.sequence, 't+v'
            done()

      s.on 'key:x', cb

      Mousetrap.trigger 'd+u'
      Mousetrap.trigger 'h+r'

      s.once 'change', ->
        Mousetrap.trigger 'h+r'
        Mousetrap.trigger 'd+u'
        Mousetrap.trigger 't+v'

      s.update 'x', 'foo', binding: [ null, [ 'h+r', 't+v' ] ]

    it 'should not re-bind when silent is passed', (done) ->

      s = new Shortcuts
        x: [
          name: 'foo'
          binding: [ null, [ 'f+v' ] ]
        ]

      times = 0

      cb = (e) ->
        assert.equal e.sequence, 'f+v'
        if ++times is 2
          done()

      s.on 'key:x', cb

      Mousetrap.trigger 'f+v'
      s.update 'x', 'foo', binding: [ null, [ 'j+g' ]], yes
      Mousetrap.trigger 'j+g'
      Mousetrap.trigger 'f+v'

