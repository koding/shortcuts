Keyconfig = require 'keyconfig'
events    = require 'events'

require 'mousetrap'
require 'mousetrap-global-bind'

module.exports =

class Shortcuts extends events.EventEmitter

  constructor: (defaults={}) ->
    
    @config = new Keyconfig defaults
    @config.on 'change', (collection, model)->
      @emit 'change', collection, model

    @_numListeners = @config.reduce (acc, x) ->
      acc[x.name] = 0
      return acc
    , {}

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


  @_osIndex =
    if /(Mac|iPhone|iPod|iPad)/i.test window.navigator.platform then 1 else 0


  _bind: (collection) ->

    index = (@_listeners[collection.name] or= {})

    collection.each (model) =>

      bindings = [].concat(model.binding[Shortcuts._osIndex]).filter(Boolean)

      if bindings.length
        listeners = (index[model.name] or= [])

        for sequence in bindings
          cb = (e) =>
            e.collection = collection
            e.model = model
            e.sequence = sequence
            @emit "key:#{collection.name}", e

          listeners.push
            sequence: sequence
            cb: cb

          if model.options?.global is true
            Mousetrap.bindGlobal sequence, cb
          else
            Mousetrap.bind sequence, cb

        return


  _unbind: (collection) ->

    index = @_listeners[collection.name]

    for key, listeners of index

      while (listener = listeners.pop())?
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
