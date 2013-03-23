class Evented
  events: null

  constructor: ->
    @events = {}

  addEvent: (eventName, [name]..., handler) ->
    @events[eventName] ?= []

    boundHandler = (e) =>
      handler arguments... if not name? or !!~e.target.name.indexOf name

    @events[eventName].push boundHandler

    remove: =>
      @events[eventName].splice i, 1 for fn, i in @events[eventName] when fn is boundHandler
      null

  trigger: (eventName, args...) ->
    handler.apply @, args for handler in @events[eventName] || []
    @parent?.trigger arguments...
    null

class Canvas extends Evented
  width: 300
  height: 150
  className: ''

  node: null
  context: null

  hitCanvas: null
  hitContext: null

  shapeIds: null
  children: null

  focus: null
  focusIndex: -1
  hover: null
  active: null

  constructor: (params = {}) ->
    super
    @[property] = value for property, value of params

    @node = document.getElementById @node if typeof @node is 'string'
    @node ?= document.createElement 'canvas'
    @node.className = @node.className.split(/\s+/).concat([@className, 'paper']).join ' '
    [@width, @height] = [@node.width, @node.height] if 'node' of params
    @node.width = @width
    @node.height = @height
    @node.setAttribute 'tabindex', 0

    @node.addEventListener 'focus', =>
      @onFocus arguments...

    @node.addEventListener 'keydown', =>
      @onKeyDown arguments...

    @node.addEventListener 'blur', =>
      @onBlur arguments...

    @node.addEventListener 'mouseleave', =>
      @onMouseLeave arguments...

    for eventName in 'mousemove mousedown mouseup click'.split /\s+/
      @node.addEventListener eventName, =>
        @handleEvent arguments...

    @context = @node.getContext '2d'

    @shapeIds = {}
    @children ?= []

    @hitCanvas ?= document.createElement 'canvas'
    @hitCanvas.className += 'hit-canvas'
    @hitContext = @hitCanvas.getContext '2d'

  add: (toAdd...) ->
    for child in toAdd
      @shapeIds[child.id] = child
      @children.push child
      child.parent = @
    null

  remove: (toRemove...) ->
    for child, i in @children by -1 when child in toRemove
      delete @shapeIds[child.id]
      @child.parent = null
      @children.splice i, 1
    null

  onFocus: (e) ->
    @focus = if @hover?.focus
      @hover
    else
      @focusIndex = 0
      @focusNext()

    @draw()

  onBlur: ->
    @focus = null
    @draw()

  onKeyDown: (e) ->
    switch e.which
      when 9 # Tab
        @focusIndex += if e.shiftKey then -1 else +1
        @focusNext()

        unless @focus?
          notCaptured = true

        @draw()

      when 13, 32 # Return, space
        @active = @focus
        @draw()

        setTimeout (=>
          @active = null
          @draw()
        ), 100

        @focus?.trigger 'click', originalEvent: e, target: @focus

      else
        notCaptured = true

    unless notCaptured
      e.preventDefault()

  onMouseLeave: ->
    @hover = null
    @draw()

  focusNext: ->
    focusable = (child for child in @children when child.focus)
    limiter = focusable.length + 1
    @focusIndex = (@focusIndex % limiter + limiter) % limiter
    @focus = focusable[@focusIndex]
    @focus

  handleEvent: (originalEvent) ->
    offsetLeft = 0
    offsetTop = 0
    offsetParent = @node
    while offsetParent?
      offsetLeft += offsetParent.offsetLeft
      offsetTop += offsetParent.offsetTop
      offsetParent = offsetParent.offsetParent

    offsetLeft = originalEvent.pageX - offsetLeft
    offsetTop = originalEvent.pageY - offsetTop

    [r, g, b, a] = (@hitContext.getImageData (offsetLeft * 3) - 1, (offsetTop * 3) - 1, 1, 1).data
    shapeId = '#' + ("0#{value.toString 16}"[-2...] for value in [r, g, b]).join ''
    target = @shapeIds[shapeId] if a is 255

    if originalEvent.type is 'mousemove' and @hover isnt target
        hoverWas = @hover || true
        @hover = target
        shouldDraw = true

    if originalEvent.type is 'mousedown' and target?
      @active = target
      shouldDraw = true

    if originalEvent.type is 'mouseup'
      @active = null
      shouldDraw = true

    if originalEvent.type is 'click'
      @focus = if target?.focus
        target
      else if target?.parent.focus
        target.parent
      else
        null
      shouldDraw = true

    if shouldDraw
      @draw()
      @node.style.cursor = target?.attr('cursor') || ''

    fauxEvent = {originalEvent, target, offsetLeft, offsetTop}

    if hoverWas?
      hoverWas.trigger? 'mouseleave', fauxEvent
      @hover?.trigger? 'mouseenter', fauxEvent
    else
      target?.trigger originalEvent.type, fauxEvent

  draw: (context = @context) ->
    context.clearRect 0, 0, @width, @height

    for child in @children
      context.save()
      child.draw context
      context.restore()

    if @hitCanvas? # Groups use this code too
      @hitCanvas.width = @width * 3
      @hitCanvas.height = @height * 3
      @hitContext.scale 3, 3
      @hitContext.clearRect 0, 0, @width, @height

      for child in @children
        @hitContext.save()
        child.draw @hitContext
        @hitContext.restore()

    null

nextId = 0
class Shape extends Evented
  id: ''
  name: ''
  parent: null

  cursor: ''
  x: 0
  y: 0
  rotate: 0
  fill: 'transparent'
  stroke: 'transparent'
  lineWidth: 0
  shadowColor: 'black'
  shadowBlur: 0
  shadowOffsetX: 0
  shadowOffsetY: 0
  focusStroke: 'red'
  focusLineWidth: 2

  constructor: (params = {}) ->
    super
    @[property] = value for property, value of params

    @id = '#' + ('00000' + nextId.toString 16)[-6...]
    nextId += 1

  attr: (attribute, value) ->
    if typeof attribute is 'string'
      if value?
        @[attribute] = value
        @parent?.draw()
        null

      else
        value = @active?[attribute] if @ is @parent.active
        value ?= @focus?[attribute] if @ is @parent.focus
        value ?= @hover?[attribute] if @ is @parent.hover
        value || @[attribute]

    else
      attributes = attribute
      @attr attribute, value for attribute, value of attributes
      null

  addTo: (parent) ->
    parent.add @
    null

  remove: ->
    @parent.remove @
    null

  moveToFront: ->
    for child, i in @parent.children when child is @
      index = i
      break

    @parent.children.splice i, 1
    @parent.children.push @
    @parent.draw()
    null

  moveToBack: ->
    for child, i in @parent.children when child is @
      index = i
      break

    @parent.children.splice i, 1
    @parent.children.unshift @
    @parent.draw()
    null

  moveForward: ->
    for child, i in @parent.children when child is @
      index = i
      break

    @parent.children.splice i, 1
    @parent.children.splice i + 1, 0, @
    @parent.draw()
    null

  moveBackward: ->
    for child, i in @parent.children when child is @
      index = i
      break

    @parent.children.splice i, 1
    @parent.children.splice i - 1, 0, @
    @parent.draw()
    null

  draw: (context) ->
    context.fillStyle = @attr 'fill'
    context.strokeStyle = @attr 'stroke'
    context.lineWidth = @attr 'lineWidth'

    if context.canvas.className is 'hit-canvas'
      context.strokeStyle = @id
      context.fillStyle = @id

    else
      context.shadowColor = @attr 'shadowColor'
      context.shadowBlur = @attr 'shadowBlur'
      context.shadowOffsetX = @attr 'shadowOffsetX'
      context.shadowOffsetY = @attr 'shadowOffsetY'

    context.translate @attr('x'), @attr('y')
    context.rotate (Math.PI / 180) *  @attr('rotate')
    context.beginPath()

    # Now draw something.

    null

  drawFocusStroke: (context) ->
    return if context.canvas.className is 'hit-canvas'

    if @parent instanceof Shape
      return unless @parent.parent.focus is @parent
    else
      return unless @parent.focus is @

    context.strokeStyle = @attr('focusStroke')
    context.lineWidth = @attr('focusLineWidth')
    context.stroke()
    null

class Ellipse extends Shape
  rh: 0
  rv: 0

  draw: (context) ->
    super
    context.save()
    [rh, rv] = [@attr('rh'), @attr('rv')]
    context.scale 1, rv / rh
    context.arc 0, 0, rh, 0, Math.PI * 2, false
    context.fill()
    context.shadowColor = 'transparent'
    context.stroke()
    context.restore()
    @drawFocusStroke arguments...
    null

class Circle extends Shape
  radius: 0

  draw: (context) ->
    super
    context.save()
    context.arc 0, 0, @attr('radius'), 0, Math.PI * 2, false
    context.restore()
    context.fill()
    context.shadowColor = 'transparent'
    context.stroke()
    @drawFocusStroke arguments...
    null

class Rectangle extends Shape
  width: 0
  height: 0

  draw: (context) ->
    super
    [width, height] = [@attr('width'), @attr('height')]
    context.moveTo 0, 0
    context.lineTo width, 0
    context.lineTo width, height
    context.lineTo 0, height
    context.closePath()
    context.fill()
    context.shadowColor = 'transparent'
    context.stroke()
    @drawFocusStroke arguments...
    null

class Line extends Shape
  points: [[0, 0]]

  draw: (context) ->
    super
    points = @attr('points').toString().split /\D+/
    context.moveTo points.splice(0, 2)...
    context.lineTo points.splice(0, 2)... until points.length is 0
    context.stroke()
    @drawFocusStroke arguments...
    null

class Polygon extends Shape
  radius: 0
  sides: 0

  draw: (context) ->
    super

    sides = @attr('sides')
    for point in [0...sides]
      context.lineTo 0, -@attr('radius')
      context.rotate (Math.PI / 180) * (360 / sides)
    context.closePath()

    context.fill()
    context.shadowColor = 'transparent'
    context.stroke()
    @drawFocusStroke arguments...
    null

Lascaux = Canvas
classes = {Canvas, Shape, Ellipse, Circle, Rectangle, Line, Polygon}
Lascaux[name] = ref for name, ref of classes

module?.exports = Lascaux
window?.Lascaux = Lascaux
