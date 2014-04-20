GameObjects = require './entities'
Window = require './window'

$ = require 'jquery'

# Extend stage to be more gamey
module.exports = class Game extends PIXI.DisplayObjectContainer
  renderer: null
  render: null
  lastTime: 0
  id: 0
  entityList: null
  entityRemovalQueue: null
  width: 1280
  height: 768
  gameOverScreen: null
  constructor: (bgColor)->
    super
    stage = new PIXI.Stage(bgColor)

    @interactive = true
    @hitArea = new PIXI.Rectangle(0, 0, @width, @height)
    @scale = Window.scale(@)

    #create a renderer instance
    @renderer = PIXI.autoDetectRenderer(
      @width * @scale.x, 
      @height * @scale.y, 
      null, 
      false, 
      false)

    setTimeout(()=>
      @gameOverScreen = $('<div class="game-over hide"><div class = "centered-text">GAME OVER</div></div>').css(
        width: window.innerWidth
        height: window.innerHeight)
      $('body').append(@gameOverScreen)
    , 1)

    #add the renderer view element to the DOM
    document.body.appendChild(@renderer.view)

    @render = () =>
      @update()
      #render the stage
      @renderer.render(stage)
      #schedule the next render
      requestAnimFrame(@render)

    @entityList = []
    @entityRemovalQueue = []

  start: ()->
    @lastTime = new Date().getTime()
    @render()

  update: ()->
    stats.begin()

    newTime = new Date().getTime()
    dt = newTime - @lastTime
    @lastTime = newTime

    width = @width
    height = @height

    for entity in @entityList
      entity

    stats.end()
  click: (event) ->
  
  tap: (event) ->
    @click.apply(@, arguments)