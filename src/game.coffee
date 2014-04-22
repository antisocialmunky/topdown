GameObjects = require './game-objects'
Window = require './window'
rgb = require('./c_utils').rgb

$ = require 'jquery'

RANDOM = Math.random
FLOOR = Math.floor
ROUND = Math.round  

stats = new Stats()
stats.setMode(0);
$(document).ready(()->
  $(stats.domElement).css(position: 'fixed')
  $('body').prepend(stats.domElement))

# Extend stage to be more gamey
module.exports = class Game extends PIXI.DisplayObjectContainer
  renderer: null
  lastTime: 0
  entityList: null
  entityCountText: 0
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
    
    stage.addChild(@)

    @entityList = []
    @entityRemovalQueue = []

  start: ()->
    @lastTime = new Date().getTime()

    setInterval(()=>
      new GameObjects.Placeholder(
        x: 1
        y: ROUND(RANDOM()*@height)
        radius: 10
        speed: 100
        game: @)
    , 200)

    @setupEntityCounter()

    @render()
  setupEntityCounter: ()->
    @entityCountText = new PIXI.Text(0, 
      font: "bold 24px Podkova"
      fill: "white"
      stroke: "white"
      align: "center"
      strokeThickness: 2)
    @entityCountText.x = 20
    @entityCountText.y = 20
    @addChild(@entityCountText)

  update: ()->
    stats.begin()
    @entityCountText.setText(@entityList.length)

    newTime = new Date().getTime()
    dt = newTime - @lastTime
    @lastTime = newTime

    width = @width
    height = @height

    for entity in @entityList
      if entity.think? then entity.think()
      if entity.tick? then entity.tick(dt)

    @performRemove()

    stats.end()
  
  add: (entity)->
    @entityList.push(entity)

  remove: (entity)->    
    @entityRemovalQueue.push(entity)

  performRemove: ()->    
    entityList = @entityList
    entityRemovalQueue = @entityRemovalQueue

    for entity in entityRemovalQueue
      i = entityList.indexOf(entity)
      if i >= 0
        entityList.splice(i, 1)
        @removeChild(entity.sprite) if entity.sprite?
    entityRemovalQueue.length = 0
    
  click: (event) ->
    x = event.global.x / @scale.x
    y = event.global.y / @scale.y

    new GameObjects.PlaceholderTower(
      color: rgb(128,255,128)
      x: ROUND(x)
      y: ROUND(y)
      radius: 20
      game: @
      filter: (entity) ->
        return entity.velocity? && entity.velocity.x == 100
      BulletClass: GameObjects.PlaceholderBullet)
  
  tap: (event) ->
    @click.apply(@, arguments)

  render: ()->