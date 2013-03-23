{Canvas, Ellipse, Circle, Rectangle, Line, Polygon} = window.Lascaux

canvas = new Canvas
  width: 300
  height: 200

canvas.addEvent 'click', 'foo', ->
  console.log 'Something named "foo" got clicked.', arguments

canvas.add new Ellipse
  x: 150
  y: 25
  rh: 15
  rv: 20
  fill: 'blue'

  hover:
    shadowColor: 'black'
    shadowBlur: 3
    shadowOffsetY: 2

canvas.add new Circle
  name: 'foo'
  cursor: 'pointer'
  x: 200
  y: 150
  radius: 100
  fill: 'red'
  stroke: 'black'
  lineWidth: 3
  shadowColor: 'black'
  shadowBlur: 10
  shadowOffsetX: 0
  shadowOffsetY: 3

  hover:
    radius: 105
    shadow: y: 10

  active:
    fill: 'orange'

  focus: true

canvas.add new Rectangle
  cursor: 'move'
  rotate: 20
  x: 50
  y: 50
  width: 100
  height: 67
  fill: 'rgba(0, 0, 255, 0.67)'
  stroke: 'blue'

  hover:
    lineWidth: 5

  active:
    fill: 'green'

  focus: true

canvas.add new Line
  stroke: 'green'
  lineWidth: 3
  x: 150
  y: 20
  points: [[0, 0], [10, 10], [20, 0], [30, 10], [40, 0], [50, 10]]

  hover:
    lineWidth: 5

canvas.add new Polygon
  name: 'foo'
  x: 250
  y: 60
  radius: 30
  sides: 6
  fill: 'green'

  hover:
    sides: 5

  active:
    sides: 4

document.body.appendChild canvas.node
document.body.appendChild canvas.hitCanvas

canvas.draw()

window.demoCanvas = canvas
