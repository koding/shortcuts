should = require 'should'
Shortcuts = require '../index'

describe 'Shortcuts', ->

  it 'should get', ->

    hub = new Shortcuts
      x: [
        { name: 'foo' }
      ]
      y: [
        { name: 'bar' }
        { name: 'baz' }
      ]

    hub.get('y').name.should.eql 'y'
    hub.get('x').name.should.eql 'x'
    hub.get('y', 'baz').name.should.eql 'baz'
    z = hub.get 'z'
    (z is undefined).should.eql yes
    should.doesNotThrow hub.get.bind(hub, 'z', 'qux')


  it 'should keep track of number of listeners', ->

    hub = new Shortcuts
      x: []
      y: []

    hub._numListeners.x.should.eql 0
    hub._numListeners.y.should.eql 0

    hub.on 'key:x', ->
    hub._numListeners.x.should.eql 1
    hub._numListeners.y.should.eql 0

    hub.once 'key:x', ->
    hub._numListeners.x.should.eql 2

    hub.removeAllListeners 'key:x'
    hub._numListeners.x.should.eql 0
