Menagerie = require 'menagerie'
Collider = Menagerie.Collider.Collider

GameObjects = require './game-objects'
Window = require './window'
rgb = require('./utils').rgb

$ = require 'jquery'

RANDOM = Math.random
FLOOR = Math.floor
ROUND = Math.round  

stats = new Stats()
stats.setMode(0);
$(document).ready(()->
  $(stats.domElement).css(position: 'fixed')
  $('body').prepend(stats.domElement))

class CircleCollider extends Collider
  collideObjects: (object1, object2)->
    if object1.position? && object1.bounds? && object2.position? && object2.bounds?
      if object1.position.sub(object2.position).length() <= object1.bounds.radius + object2.bounds.radius
        object1.collide(object1._entity, object2._entity)
        return true
    return false

# Extend stage to be more gamey
module.exports = class Game extends PIXI.DisplayObjectContainer
  renderer: null
  lastTime: 0
  entityList: null
  entityCountText: 0
  entityRemovalQueue: null
  bodyRemovalQueue: null
  width: 1280
  height: 768
  gameOverScreen: null
  map: null
  collider: null
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
    @bodyRemovalQueue = []
    @map = new Menagerie.TileMap(
      pixelWidth: 32
      pixelHeight: 32
      tileWidth: 40
      tileHeight: 24)

    @collider = new CircleCollider

  start: ()->
    @lastTime = new Date().getTime()

    setInterval(()=>
      new GameObjects.Placeholder(
        x: 1
        y: ROUND(RANDOM()*@height)
        radius: 10
        speed: 100
        game: @
        map: @map
        collider: @collider)
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
    
    @collider.collide()

    for entity in @entityList
      if entity.tick? then entity.tick(dt)

    @performRemove()

    stats.end()
  
  add: (entity)->
    @entityList.push(entity)

  remove: (entity)->    
    @entityRemovalQueue.push(entity)

  removeBody: (body)->    
    @bodyRemovalQueue.push(body)

  performRemove: ()->    
    entityList = @entityList
    entityRemovalQueue = @entityRemovalQueue
    bodyRemovalQueue = @bodyRemovalQueue

    for entity in entityRemovalQueue
      i = entityList.indexOf(entity)
      if i >= 0
        entityList.splice(i, 1)
        @removeChild(entity.sprite) if entity.sprite?
    entityRemovalQueue.length = 0

    for body in bodyRemovalQueue
      @collider.remove(body)
    bodyRemovalQueue.length = 0
    
  click: (event) ->
    x = event.global.x / @scale.x
    y = event.global.y / @scale.y

    x = (FLOOR(x / @map.pixelWidth) + 0.5) * @map.pixelWidth
    y = (FLOOR(y / @map.pixelHeight) + 0.5) * @map.pixelHeight

    if @map.filter(
      (element)->
        return element instanceof GameObjects.PlaceholderTower
      , x, y).length == 0

      new GameObjects.PlaceholderTower(
        color: rgb(128,255,128)
        x: ROUND(x)
        y: ROUND(y)
        radius: 16
        game: @
        map: @map
        collider: @collider
        BulletClass: GameObjects.PlaceholderBullet)
  
  tap: (event) ->
    @click.apply(@, arguments)

  render: ()->