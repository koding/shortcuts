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


  it 'should keep track of number of listeners', ->

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


  it 'should bind/unbind sets automatically', ->
    
    s = new Shortcuts
      x: [
        { name: 'a', binding: [ ['z'], ['x', 'y'] ] },
        { name: 'b', binding: [ null, ['a+b'] ] }
      ]

    cbCalled = 0
    cb = (e, collection, model) ->
      cbCalled++

    s.on 'key:x', cb

    s._listeners.should.have.ownProperty 'x'
    Object.keys(s._listeners).should.have.lengthOf 1

    s._listeners.x.should.have.ownProperty 'a'
    s._listeners.x.should.have.ownProperty 'b'
    s._listeners.x.a.should.be.Array
    s._listeners.x.a.should.have.lengthOf 2
    s._listeners.x.a[0].sequence.should.eql 'x'
    Mousetrap.trigger 'x'
    Mousetrap.trigger 'x'
    cbCalled.should.eql 2

    s.removeListener 'key:x', cb
    Mousetrap.trigger 'x'
    cbCalled.should.eql 2

