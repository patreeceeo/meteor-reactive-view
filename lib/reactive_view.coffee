
# A View class that serves as a thin wrapper around a Meteor
# template object, providing a cleaner, DRYer interface (and one
# more familiar to those coming from an MVC framework) without
# getting in the way or interfering with Meteor's reactivity.
#
# {ReactiveView} offers the following extension points to derived
# classes:
# template - a [Meteor template object](http://docs.meteor.com/#templates_api)
# rendered - a callback, will be called immediately if the
#                 template has already rendered
# helpers - [template helpers](http://docs.meteor.com/#template_helpers)
# els - an {Object} mapping names to DOM selector {String}s, a 
#       corresponding mapping will be made available under the 
#       `$els` property using jQuery arrays in place of the DOM 
#       selector {String}s.
# events - Like [template events](http://docs.meteor.com/#template_events). 
#          Additional features: the event string can contain a 
#          name from the `els` object instead of the corresponding
#          DOM selector {String} (see Examples). Like with
#          Backbone.View, the names ({String}s) of instance 
#          methods may be used instead of actual {Function}s.
#
# ## Example
#
# ```coffee
#   class GameView extends ReactiveView
#     template: Template.game
#     els: 
#       board: '.js-gb'
#       playersLetters: '.js-gbletters'
#       scoreboard: '#score'
#     events:
#       'click board': 'tryMove'
#       'keypress board': (event) ->
#         if enterKeyPress(event)
#           @tryMove(event)
# ```
#       
class ReactiveView

  @_templateInst ?= {}

  ### Public ###
 
  # Constructor
  #
  # config - an {Object} which may contain any of the extension 
  #          points documented in the {ReactiveView} overview
  constructor: (@config = {}) ->
    @template ?= @_getConfig('template')
    @template.isRendered ?= false
    @template.destroyed = 
      @_getConfig('destroyed', (->), callback: true)
    view = this
    @template.rendered = ->
      ReactiveView._templateInst[view.template.guid] = this
      view.template.isRendered = true
      view.viewHelper()
      view._getConfig('rendered', (->), callback: true)
        .call(this)

    @_assignEventsToTemplate()
    @_assignHelpersToTemplate()

    @model ?= @_getConfig('model', null, optional: true)
    @initialize(@config)

  viewHelper: ->
    _.defer =>
      @_cacheElementLists()
    undefined

  getTemplateInstance: ->
    ReactiveView._templateInst[@template.guid]

  # Override to add initialization logic to a derived
  # class
  initialize: ->

  # A shortcut for the template instance's $
  $: (selector) ->
    # Won't have a template instance until the template has
    # rendered.
    @getTemplateInstance()?.$(selector)

  # Another name for {ReactiveView::$}
  findAll: (selector) ->
    @$(selector)

  ### Internal ###

  _getConfig: (
    name, 
    defaultValue, 
    { callback, optional } = {}
  ) ->
    error = Error "ReactiveView wants a(n) #{name}."
    value = 
      if callback
        @config[name] or @[name] or defaultValue
      else
        _.result(@config, name) or 
          _.result(this, name) or 
          defaultValue
    unless value? or optional
      throw error
    value

  _assignHelpersToTemplate: ->
    boundHelpers = {}
    for own key, helper of @_getConfig('helpers', {})
      view = this
      boundHelpers[key] = _.wrap helper, (helper, args...) ->
        view.viewHelper()
        helper.call(view, this, args...)

    @template.helpers boundHelpers

  _buildEventSelector: (selector) ->
    els = @_getConfig('els', {})
    [eventName, rest...] = selector.split RegExp '\\s+'
    elsKey = rest.join(' ')
    "#{eventName} #{els[elsKey] or elsKey}"

  # TODO: Figure out how to re-assign event handlers to template.
  #       Perhaps binding via jQuery would work.
  _assignEventsToTemplate: ->
    events = {}
    for own key, value of @_getConfig('events', {})
      eventSelector = @_buildEventSelector(key)
      handler = 
        if _.isFunction(value)
          value
        else if _.isString(value)
          @_getConfig(value, null, callback: true)

      unless _.isFunction(handler)
        throw Error "ReactiveView event maps must specify 
                     handlers by method name or closure. Event '#{key}' is mapped to #{value}." 

      events[eventSelector] = _.bind(handler, this)

    @template.events events

  _cacheElementLists: ->
    @$els ?= {}
    for own key, value of @_getConfig('els', {})
      @$els[key] = @$(value)

    undefined


