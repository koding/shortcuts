Keyconfig = require 'keyconfig'
events = require 'events'

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

    @_os =
      if /(Mac|iPhone|iPod|iPad)/i.test window.navigator.platform then 1 else 0

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

  
  _bind: (collection) ->

  _unbind: (collection) ->


  get: (collectionName, modelName) ->
    collection = @config.find name: collectionName
    if not modelName or (modelName and not collection)
      return collection
    else
      model = collection.find name: modelName
      return model
