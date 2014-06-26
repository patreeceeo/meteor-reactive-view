# render and put in the document
renderToDiv = (comp) ->
  div = document.createElement "DIV"
  UI.materialize comp, div
  div

# for events to bubble an element needs to be in the DOM.
# @return {Function} call this for cleanup
addToBody = (el) ->
  document.body.appendChild el
  ->
    document.body.removeChild el

xTinytest =
  add: ->
  addAsync: ->

if Meteor.isClient

  Template.__define__ 'listKimchis', -> [
    Spacebars.TemplateWith (=>
      {title: Spacebars.call(@lookup("title"))}
    ), UI.block =>
      Spacebars.include @lookupTemplate "listKimchis_title"
    HTML.Raw("<p>#{Spacebars.mustache @lookup 'description'}</p>")
    HTML.UL(
      UI.Each @lookup('kimchis'), UI.block ->
        [HTML.Raw "<li>#{Spacebars.mustache @lookup 'name'}</li>"]
    )
  ]

  Template.__define__ 'listKimchis_title', -> 
    [
      HTML.Raw("<h1>#{Spacebars.mustache @lookup 'title'}</h1>")
    ]
    
  class KimchiView extends ReactiveView
    template: Template.listKimchis
    helpers:
      kimchis: ->
        [
          { name: 'traditional' }
          { name: 'con habanero (very spicy)' }
          { name: 'white raddish' }
        ]

  withTemplateInBody = (fn) ->
    div = renderToDiv Template.listKimchis
    cleanUp = addToBody div
    fn(div)
    cleanUp()

  Tinytest.add 'ReactiveView - _getConfig()', (test) ->
    class BrewView extends KimchiView
      alsoFermented: 'beer'
      callMe: -> 'hello'

    view1 = new BrewView
    view2 = new BrewView
      alsoFermented: 'kombucha'
    view3 = new BrewView
      alsoFermented: -> 'kombucha'

    test.equal 'beer', view1._getConfig('alsoFermented'), 
      "class defaults: prototype properties should also be considered 
      possible config values"

    test.equal 'kombucha', view2._getConfig('alsoFermented'), 
      "class defaults: values passed via constructor config object arg 
      should take precedence over prototype properties"

    test.equal 'kombucha', view3._getConfig('alsoFermented'),
      "delayed-binding: if the config value is specified as a function 
      then the return value should be used as the actual config value"

    # it should throw an error for an undefined config value
    test.throws -> view1._getConfig 'flavor'

    test.equal 'tangy', view1._getConfig('flavor', 'tangy'),
      "it should return an argued default when the config value is undefined"

    test.equal 'hello', view1._getConfig('callMe', '', callback: true)()

    test.isNull view1._getConfig('inconceivable', 
        null, optional: true
      ),
      "should allow null values if optional flag set"

  # There's currently no way to unbind event handlers once bound to
  # a template, so this test causes a subsequent test involving
  # events to fail. Pend it for now since the other test also
  # tests events.
  #
  # leads:
  # Template.instance.dom.remove() destroys the template instance
  # HandlerRec.prototype.unbind() directly unbinds a single
  #   handler if its possible to get an instance
  # Use the template instance's $() to bind events
  Tinytest.add 'ReactiveView - event binding', (test) ->

    eventHandled = false
    otherEventHandled = false

    view = new KimchiView
      events:
        'click li': ->
          eventHandled = true
        'keypress li': ->
          otherEventHandled = true

    withTemplateInBody (subtree) ->

      $(subtree).find('li').click()

      test.isTrue eventHandled, "it should take an events config object that is
        used to attach event handlers to the template instance's DOM"

      $(subtree).find('li').keypress()

      test.isTrue otherEventHandled, "regression: make sure each event handler is 
        properly bound to the corresponding event/selector"

      

  Tinytest.add 'ReactiveView - helpers', (test) ->
    view = new KimchiView
      helpers:
        title: ->
          'Kimchis'
        description: ->
          'a tangy, spicy Korean slaw typically made with cabbage and fermented
          in jars buried in the earth for several months.'

    withTemplateInBody (subtree) ->
      test.equal 'Kimchis', $(subtree).find('h1').text(),
        "it should take an helpers config object that can be used in the template"
      test.notEqual 'Kimchis', $(subtree).find('p').text(),
        "regression: make sure each helper is properly mapped to its name"

    
  Tinytest.add 'ReactiveView - scoped jQuery', (test) ->
    withTemplateInBody (subtree) ->

      view = new KimchiView

      test.length view.$('h1'), 1
      test.length view.$('li'), 3

  Tinytest.addAsync 'ReactiveView - elements/events', (test, done) ->

    eventHandled = false
    otherEventHandled = false
    new KimchiView
      els:
        'list': 'ul'
        'items': 'ul > li'
      events:
        'click list': 'onClickList'
        'click items': ->
          otherEventHandled = true
      onClickList: ->
        eventHandled = true
      rendered: ->
        test.length @$els.list, 1
        test.length @$els.items, 3
        @$els.list.click()
        @$els.items.click()
        test.isTrue eventHandled, 'elements aliases in the events object should work the same as the selector for the elements'
        test.isTrue otherEventHandled, 'elements aliases in the events object should work the same as the selector for the elements'
        done()

    withTemplateInBody ->

      test.throws ->
        new KimchiView 
          events:
            'click list': 'foo'

      test.throws ->
        new KimchiView
          events:
            'click list': {}


  Tinytest.add 'ReactiveView - model', (test) ->
    model = 
      get: (name) ->
        "#{name} value"
      set: (name) ->

    view = new KimchiView
      model: model

    test.equal view.model, model, "should make its model easy to access"

