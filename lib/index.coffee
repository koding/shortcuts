Keyconfig = require 'keyconfig'
events    = require 'events'
os        = require 'component-os'

require 'mousetrap'
require 'mousetrap-global-bind'

module.exports =

class Shortcuts extends events.EventEmitter

  constructor: (defaults={}) ->

    @config = new Keyconfig defaults

    @_numListeners = @config.reduce (acc, x) ->
      acc[x.name] = 0
      return acc
    , {}

    @config.on 'change', (collection, model) =>
      if @_numListeners[collection.name] > 0
        @_resetBinding collection, model
      @emit 'change', collection, model
      return

    @_listeners = {}

    transform = (event) =>
      [ eventName, collectionName ] = event.split ':'
      return undefined  if eventName isnt 'key' or not (collection = @get collectionName)
      return collection

    @on 'newListener', (event) =>
      return undefined  unless (collection = transform event)
      @_bind collection  if ++@_numListeners[collection.name] is 1

    @on 'removeListener', (event) =>
      return undefined  unless (collection = transform event)
      @_unbind collection  if --@_numListeners[collection.name] is 0

    super()


  removeAllListeners: (type) ->

    throw new Error 'missing type'  unless type

    super type


  _resetBinding: (collection, model) ->

    index = @_listeners[collection.name]

    listeners = index[model.name]

    while (listener = listeners?.pop())?
      Mousetrap.unbind listener.sequence

    listeners = @_bindKeys collection, model

    if listeners.length
      index[model.name] = listeners
    else
      delete index[model.name]


  _bind: (collection) ->

    index = (@_listeners[collection.name] or= {})

    collection.each (model) =>

      listeners = @_bindKeys collection, model
      if listeners.length
        index[model.name] = listeners

    return


  _bindKeys: (collection, model) ->

    bindings = getPlatformBindings model
    listeners = []

    if bindings.length

      bindings.forEach (sequence) =>

        cb = (e) =>
          e.collection = collection
          e.model      = model
          e.sequence   = sequence

          @emit "key:#{collection.name}", e

        listener =
          sequence : sequence
          cb       : cb

        listeners.push listener

        if model.options?.global is true
          Mousetrap.bindGlobal listener.sequence, listener.cb
        else
          Mousetrap.bind listener.sequence, listener.cb

    return listeners


  _unbind: (collection) ->

    index = @_listeners[collection.name]

    for key, listeners of index

      while (listener = listeners?.pop())?
        Mousetrap.unbind listener.sequence, listener.cb

      delete index[key]

    delete @_listeners[collection.name]

    return


  get: (collectionName, modelName) ->

    collection = @config.find name: collectionName
    if not modelName or (modelName and not collection)
      return collection
    else
      model = collection.find name: modelName
      return model


  update: (collectionName, modelName, value, silent=no) ->

    unless (collection = @get collectionName)
      throw "#{collectionName} not found"

    return collection
      .update modelName, value, silent
      .find name: modelName


getPlatformBindings = (model) ->
  bindings = if os is 'mac' then model.getMacKeys() else model.getWinKeys()
  return [].concat(bindings).filter(Boolean)
