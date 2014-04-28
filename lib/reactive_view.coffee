
UI.registerHelper 'block', (block, modifiers..., options) ->
  View::buildBEMClassName block, null, modifiers

UI.registerHelper 'element', (block, element, modifiers..., options) ->
  View::buildBEMClassName block, element, modifiers

class View
  constructor: (options) ->
    view = this
    @template.rendered = ->
      view.templateInstance = this
    @_assignEventsToTemplate()
    @_assignDataHelpersToTemplate()
    @initialize(options)

  initialize: ->

  find: (selector) ->
    # @templateInstance.findAll(@buildBEMSelector(selector))
    $(@buildBEMSelector(selector))

  _cacheNC: ->
    nc = {}
    for own key, value of @nc
      nc[key] = @templateInstance.findAll(@buildBEMSelector(value))
    @nc = nc

  _assignDataHelpersToTemplate: ->
    boundHelpers = {}
    for key, fn of @dataHelpers or {}
      do =>
        localFn = fn
        boundHelpers[key] = (args...) =>
          localFn.apply this, args

    @template.helpers boundHelpers

  buildEventSelector: (selector) ->
    "#{selector.event} #{
      @buildBEMSelector selector
    }"

  buildBEM: ({block: block, element: element, modifiers: modifiers}, options) ->
    element ?= []
    modifiers ?= []
    prefix = options.prefix or ''
    delimiter = options.delimiter or ''

    baseSelector =
      if element isnt ''
        "#{prefix}#{block}-#{element}"
      else
        "#{prefix}#{block}"

    modifierSelectors =
      for modifier in modifiers
        if element?
          "#{prefix}#{block}-#{element}--#{modifier}"
        else
          "#{prefix}#{block}--#{modifier}"

    "#{baseSelector} #{modifierSelectors.join(delimiter)}"

  buildBEMSelector: (selector) ->
    @buildBEM selector,
      prefix: '.'
      delimiter: ''

  buildBEMClassName: (selector) ->
    @buildBEM selector
      prefix: ''
      delimiter: ' '

  _assignEventsToTemplate: ->
    @template.events = {}
    for key, object of @events or {}
      eventSelector = @buildEventSelector(object)
      do =>
        localFn = object.callback
        @template.events[eventSelector] = (args...) =>
          # TODO: support strings as well as functions for callback value
          localFn.apply this, args



