should    = require 'should'
Shortcuts = require '../index'

describe 'Shortcuts', ->

  it 'should get', ->

    s = new Shortcuts
      x: [
        { name: 'foo' }
      ]
      y: [
        { name: 'bar' }
        { name: 'baz' }
      ]

    s.get('y').name.should.eql 'y'
    s.get('x').name.should.eql 'x'
    s.get('y', 'baz').name.should.eql 'baz'
    z = s.get 'z'
    (z is undefined).should.eql yes
    should.doesNotThrow s.get.bind(s, 'z', 'qux')

  it 'should update num of listeners', ->

    s = new Shortcuts
      x: []
      y: []

    s._numListeners.x.should.eql 0
    s._numListeners.y.should.eql 0

    s.on 'key:x', ->
    s._numListeners.x.should.eql 1
    s._numListeners.y.should.eql 0

    s.once 'key:x', ->
    s._numListeners.x.should.eql 2

    s.removeAllListeners 'key:x'
    s._numListeners.x.should.eql 0

  it 'removeAllListeners should always expect a type', ->

    s = new Shortcuts
    should.throws s.removeAllListeners

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
          e.sequence.should.eql 'y'
          e.collection.name.should.eql 'x'
          e.model.name.should.eql 'a'
        if n is 'y'
          e.sequence.should.eql 'a+b'
          e.collection.name.should.eql 'y'
          e.model.name.should.eql 'c'
      times++

    cbx = cb.bind cb, 'x'
    cby = cb.bind cb, 'y'

    s.on 'key:x', cbx

    Object.keys(s._listeners).should.have.lengthOf 1

    s.on 'key:y', cby
    Object.keys(s._listeners).should.have.lengthOf 2

    s._listeners.should.have.ownProperty 'x'
    s._listeners.should.have.ownProperty 'y'
    s._listeners.x.should.have.ownProperty 'a'
    s._listeners.x.should.have.ownProperty 'b'
    s._listeners.x.a.should.be.Array
    s._listeners.x.a.should.have.lengthOf 2
    s._listeners.x.a[0].sequence.should.eql 'x'

    Mousetrap.trigger 'y'
    Mousetrap.trigger 'y'
    times.should.eql 2

    Mousetrap.trigger 'a+b'
    times.should.eql 3

    s.removeListener 'key:x', cbx

    Object.keys(s._listeners).should.have.lengthOf 1

    Mousetrap.trigger 'y'
    times.should.eql 3

    Mousetrap.trigger 'a+b'
    times.should.eql 4

    s.removeAllListeners 'key:y'
    Mousetrap.trigger 'a+b'
    times.should.eql 4

    Object.keys(s._listeners).should.have.lengthOf 0

    times = 0
    s._numListeners.x.should.eql 0
    s.once 'key:x', cbx
    s._numListeners.x.should.eql 1
    Object.keys(s._listeners).should.have.lengthOf 1
    Mousetrap.trigger 'y'
    times.should.eql 1
    Object.keys(s._listeners).should.have.lengthOf 0
    Mousetrap.trigger 'y'
    times.should.eql 1

  describe 'update', ->

    it 'should update existing models and emit change', (done) ->

      s = new Shortcuts
        x: [
          name: 'foo'
          binding: [ null, [ 'z' ] ]
        ]

      model = s.get('x', 'foo')
      model.getMacKeys().should.eql [ 'z' ]

      s.once 'change', (collection, model) ->
        collection.name.should.eql 'x'
        model.name.should.eql 'foo'
        model.getMacKeys().should.eql [ 'y' ]
        done()

      changed = s.update 'x', 'foo', binding: [ null, [ 'y' ] ]
      changed.should.eql model

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
            e.sequence.should.eql 'z+s'
          when 2
            e.sequence.should.eql 'y+f'
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
            e.sequence.should.eql 'd+u'
          when 2
            e.sequence.should.eql 'h+r'
          when 3
            e.sequence.should.eql 'h+r'
          when 4
            e.sequence.should.eql 't+v'
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
        e.sequence.should.eql 'f+v'
        if ++times is 2
          done()

      s.on 'key:x', cb

      Mousetrap.trigger 'f+v'
      s.update 'x', 'foo', binding: [ null, [ 'j+g' ]], yes
      Mousetrap.trigger 'j+g'
      Mousetrap.trigger 'f+v'
