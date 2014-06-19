Menagerie = require 'menagerie'
Collider = Menagerie.Collider.Collider

GameObjects = require './game-objects'
Window = require './window'
rgb = require('./utils').rgb

$ = require 'jquery'

RANDOM = Math.random
FLOOR = Math.floor
ROUND = Math.round  
MAX = Math.max

stats = new Stats()
stats.setMode(0)

class CircleCollider extends Collider
  collideObjects: (object1, object2)->
    if object1.position? && object1.bounds? && object2.position? && object2.bounds?
      if object1.position.sub(object2.position).length() <= object1.bounds.radius + object2.bounds.radius
        object1.collide(object1._entity, object2._entity)
        return true
    return false

cost = (tile) -> 
  if tile.bins.structure > 0 && !tile.bins.chapel
    return 10
  else if tile.bins.mover > 0
    return 2
  return 1

zOrder = (a,b)->
  return a.y - b.y

ThingsToAdd =
  Towers: 0
  Walls: 1
  Chapel: 2

# Extend stage to be more gamey
module.exports = class Game extends PIXI.DisplayObjectContainer
  renderer: null
  lastRenderTime: 0
  lastUpdateTime: 0
  enemyTargets: null
  spawnEnemies: false
  spawnPeriod: 100 #in ms
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
  addMode: ThingsToAdd.Towers 
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
      pixelWidth: 64
      pixelHeight: 64
      width: 1280
      height: 768

    @enemyTargets = []

  start: ()->
    @lastRenderTime = new Date().getTime()
    @lastUpdateTime = @lastRenderTime

    mapContainer = new PIXI.DisplayObjectContainer()
    @addChild(mapContainer)

    for x in [0..1280] by 32
      for y in [0..768] by 32
        sprite = new PIXI.Sprite.fromImage('./assets/GrassTile.png')
        sprite.x = x
        sprite.y = y
        mapContainer.addChild(sprite)

    setInterval(()=>
      if @spawnEnemies
        direction = FLOOR(RANDOM() * 4)
        switch direction
          when 0
            tile = @map.get(1, RANDOM() * @height)
          when 1
            tile = @map.get(RANDOM() * @width, @height - 1)
          when 2
            tile = @map.get(@width - 1, RANDOM() * @height)
          when 3
            tile = @map.get(RANDOM() * @width, 1)
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
    , @spawnPeriod)

    @setupUI()
    @setupEntityCounter()

    @startRendering()
    setInterval(()=>
      @update()
    , @updatePeriod)

  setupUI: ()->
    $(document).ready(()=>
      $(stats.domElement).css(position: 'fixed')
      $('body').prepend(stats.domElement)

      uiPanel = $('<ul class="ui-panel"></ul>')
      toggleEnemies = $('<li class="toggle-enemies">Enemies?</li>').click(()=> @spawnEnemies = !@spawnEnemies)
      pickTowers = $('<li class="pick-towers">Towers</li>').click(()=> @addMode = ThingsToAdd.Towers)
      pickWalls = $('<li class="pick-walls">Walls</li>').click(()=> @addMode = ThingsToAdd.Walls)
      pickChapel = $('<li class="pick-chapel">Chapel</li>').click(()=> @addMode = ThingsToAdd.Chapel)
      uiPanel.append(toggleEnemies)
      uiPanel.append(pickTowers)
      uiPanel.append(pickWalls)
      uiPanel.append(pickChapel)
      $('body').append(uiPanel))

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

    pathingQueue = @pathingQueue
    paths = 0
    @children.sort(zOrder)
    while new Date().getTime() - newTime < 20 && pathingQueue.queue.length > 0
      pathingQueue.path()
      paths++

    #console.log "Paths " + paths
  
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
        entity.destroy() if entity.destroy?
      i = @enemyTargets.indexOf(entity)
      if i >= 0
        @enemyTargets.splice(i, 1)
    entityRemovalQueue.length = 0

    for body in bodyRemovalQueue
      @collider.remove(body)
    bodyRemovalQueue.length = 0
    
  click: (event) ->
    tile = @map.get(event.global.x / @scale.x, event.global.y / @scale.y)
    center = tile.center

    if !tile.bins.structure
      switch @addMode
        when ThingsToAdd.Towers
          new GameObjects.PlaceholderTower(
            color: rgb(128,255,128)
            x: ROUND(center.x)
            y: ROUND(center.y)
            radius: 16
            game: @
            map: @map
            collider: @collider
            rangeRadius: 100
            BulletClass: GameObjects.PlaceholderBullet)
        when ThingsToAdd.Walls
          new GameObjects.PlaceholderWall(
            x: ROUND(center.x)
            y: ROUND(center.y)
            radius: 10
            game: @
            map: @map
            collider: @collider)
        when ThingsToAdd.Chapel
          @enemyTargets.push(new GameObjects.PlaceholderChapel(
            color: rgb(255,255,64)
            x: ROUND(center.x)
            y: ROUND(center.y)
            radius: 10
            game: @
            map: @map
            collider: @collider))
  
  tap: (event) ->
    @click.apply(@, arguments)

  startRendering: ()->