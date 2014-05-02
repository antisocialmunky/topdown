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

cost = (tile) -> 
  if tile.length > 0
    return false
  return 1

# Extend stage to be more gamey
module.exports = class Game extends PIXI.DisplayObjectContainer
  renderer: null
  lastRenderTime: 0
  lastUpdateTime: 0
  updatePeriod: 100 #in ms
  entityList: null
  entityCountText: 0
  entityRemovalQueue: null
  bodyRemovalQueue: null
  width: 1280
  height: 768
  gameOverScreen: null
  map: null
  pathingQueue: null
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

    @startRendering = () =>
      @render()
      #render the stage
      @renderer.render(stage)
      #schedule the next render
      requestAnimFrame(@startRendering)
    
    stage.addChild(@)

    @entityList = []
    @entityRemovalQueue = []
    @bodyRemovalQueue = []
    @map = new Menagerie.TileMap(
      pixelWidth: 32
      pixelHeight: 32
      tileWidth: 40
      tileHeight: 24)

    @pathingQueue = new Menagerie.TileMap.PathingQueue
      algorithm: Menagerie.TileMap.AStar
      cost: cost
    @collider = new CircleCollider

  start: ()->
    @lastRenderTime = new Date().getTime()
    @lastUpdateTime = @lastRenderTime

    setInterval(()=>
      tile = @map.get(1, RANDOM() * @height)
      center = tile.center

      create = true
      if tile.length > 0
        create = false

      if create
        new GameObjects.Placeholder(
          x: center.x
          y: center.y
          radius: 10
          speed: 40
          game: @
          map: @map
          collider: @collider
          pathingQueue: @pathingQueue)
    , 100)

    @setupEntityCounter()

    @startRendering()
    setInterval(()=>
      @update()
    , @updatePeriod)

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

  render: ()->
    stats.begin()
    @entityCountText.setText(@entityList.length)

    newTime = new Date().getTime()
    dt = newTime - @lastRenderTime
    @lastRenderTime = newTime
    
    @collider.collide()

    for entity in @entityList
      if entity.tick? then entity.tick(dt)

    @performRemove()

    stats.end()

  update: ()->
    newTime = new Date().getTime()
    dt = newTime - @lastUpdateTime
    @lastUpdateTime = newTime

    for entity in @entityList
      if entity.think? then entity.think(dt)
      if entity.clean? then entity.clean()

    for i in [1..3]
      @pathingQueue.path()
  
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
    center = @map.get(event.global.x / @scale.x, event.global.y / @scale.y).center

    if @map.filter(
      (element)->
        return element instanceof GameObjects.PlaceholderTower
      , center.x, center.y).length == 0

      new GameObjects.PlaceholderTower(
        color: rgb(128,255,128)
        x: ROUND(center.x)
        y: ROUND(center.y)
        radius: 16
        game: @
        map: @map
        collider: @collider
        pathingQueue: @pathingQueue
        BulletClass: GameObjects.PlaceholderBullet)
  
  tap: (event) ->
    @click.apply(@, arguments)

  startRendering: ()->