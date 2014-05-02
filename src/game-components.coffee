Sentai = require 'sentai'
Menagerie = require 'menagerie'
ADT = Menagerie.ADT
TileMap = Menagerie.TileMap
Collidable = Menagerie.Collider.Collidable

Vector2D = ADT.Vector2D
Bounds = ADT.Bounds

rgb = require('./utils').rgb

FLOOR = Math.floor
ROUND = Math.round
SQRT = Math.sqrt
MIN = Math.min
RANDOM = Math.random

Sentai.componentize(class GameFunctions
  game: null
  removed: false
  constructor: (options)->
    @game = options.game
    @game.add(@_entity)
  addSprite: (sprite)->
    @game.addChild(sprite)
  remove: ()->
    if !@removed
      @game.remove(@_entity)
      @removed = true)
.observes(addSprite: 'sprite')
.listensTo('remove')

Sentai.componentize(class StaticObject
  position: null
  constructor: (options)->
    @position = new Vector2D
      x: options.x
      y: options.y)
.sync('position')

Sentai.componentize(class MovingObject extends StaticObject
  velocity: null
  constructor: (options)->
    super
    @velocity = options.velocity || new Vector2D
    @velocity = @velocity.divideByScalar(1000)
  tick: (dt)->
    @position = @position.add(@velocity.multiplyByScalar(dt))
  setPosition: (position)->
    @position = position
  setVelocity: (velocity)->
    @velocity = velocity)
.sync('position', 'velocity')
.observes(
  setPosition: 'position'
  setVelocity: 'velocity')
.listensTo('tick')
  
Sentai.componentize(class StaticTileObject extends StaticObject
  tile: null
  map: null
  constructor: (options)->
    super
    @map = options.map
    @map.add(@_entity)
    @tile = @_entity._tile
  remove: ()->
    @tile.remove(@_entity))
.sync('tile')
.listensTo('remove')
 
TILE_MOVING_STATES = 
  WAITING: 0
  INTERPOLATING: 1

Sentai.componentize(class MovingTileObject extends StaticTileObject
  waypoints: null
  speed: 1 #speed per second
  velocity: new Vector2D
  state: TILE_MOVING_STATES.WAITING
  remainingDt: 0
  constructor: (options)->
    super
    @waypoints = []
    @speed = options.speed
  tick: (dt)->
    switch @state
      when TILE_MOVING_STATES.WAITING
        if @waypoints[0]?
          target = @waypoints[0]
          repath = false
          if target.length > 0
            repath = true
          if repath
            @_entity.resetPath()
          else
            @waypoints.shift();
            velocity = target.center.sub(@tile.center)
            distance = velocity.length()
            @remainingDt = distance / @speed * 1000
            @velocity = velocity.normalize().multiplyByScalar(@speed / 1000)
            @state = TILE_MOVING_STATES.INTERPOLATING

            #we want to reserve the space this goes into to prevent others from doing so
            target.add(@_entity)
            @tile = target
      when TILE_MOVING_STATES.INTERPOLATING
        nextDt = MIN(@remainingDt, dt)
        @remainingDt -= dt
        @position = @position.add(@velocity.multiplyByScalar(nextDt))
        if @remainingDt <= 0
          @state = TILE_MOVING_STATES.WAITING
  setWaypoints: (waypoints)->
    @waypoints = waypoints
  setPosition: (position)->
    @position = position)
.sync('waypoints')
.observes(
  setWaypoints: 'waypoints'
  setPosition: 'position')
.listensTo('tick')

Sentai.componentize(class Body extends Collidable
  game: null
  constructor: (options)->
    @game = options.game
    @collider = options.collider
    super
    @collider.add(@)
  setPosition: (position)->
    @position = position
  collide: ()->
  remove: ()->
    @game.removeBody(@))
.sync('bounds')
.observes(setPosition: 'position')
.listensTo('collide', 'remove')

Sentai.componentize(class FriendlyBullet extends Body
  constructor: (options)->
    super
      layer: 'friendly-bullet'
      layersToCollide: ['enemy']
      bounds: new Bounds
        radius: options.radius
      game: options.game
      collider: options.collider
  collide: (object1, object2)->
    object1.remove()
    object2.remove())

Sentai.componentize(class FriendlyBody extends Body
  constructor: (options)->
    super
      layer: 'friendly'
      bounds: new Bounds
        radius: options.radius
      game: options.game
      collider: options.collider)

Sentai.componentize(class EnemyBody extends Body
  constructor: (options)->
    super
      layer: 'enemy'
      bounds: new Bounds
        radius: options.radius
      game: options.game
      collider: options.collider)

Sentai.componentize(class Range extends Body
  rangeColor: rgb(255,0,0)
  rangeRadius: 100
  rangeSprite: null
  targets: null
  constructor: (options, collidableOptions)->
    @rangeRadius = options.rangeRadius || @rangeRadius
    
    @targets = []
    rangeSprite = @rangeSprite = new PIXI.Graphics()
    
    rangeSprite.lineStyle(1, @rangeColor)
    rangeSprite.drawCircle(0, 0, @rangeRadius)

    collidableOptions.bounds = new Bounds
      radius: @rangeRadius
    super(collidableOptions)
  setSprite: (sprite)->
    sprite.addChild(@rangeSprite)
  clean: ()->
    @targets = []
  collide: (object1, object2)->
    @targets.push(object2))
.sync('rangeRadius', 'targets')
.observes(setSprite: 'sprite')
.listensTo('clean')

Sentai.componentize(class FriendlyRange extends Range
  constructor: (options)->
    super(options,
      layer: 'friendly-range'
      layersToCollide: ['enemy']
      game: options.game
      collider: options.collider))

Sentai.componentize(class DecisionMaker
  think: (dt)->) #lives on the thinking loop rather than the rendering one
.listensTo('think')

Sentai.componentize(class MovesAroundRandomly extends DecisionMaker
  waypoints: null
  start: null
  end: null
  map: null
  sprite: null
  reset: false
  scheduled: false
  pathingQueue: null
  constructor: (options)->
    super
    @game = options.game
    @map = options.map
    @pathingQueue = options.pathingQueue
    @waypoints = []
  think: ()->
    if @reset
      @findPath()
    else if @start? && @waypoints.length == 0
      @end = @map.get(@map.totalPixelWidth - 1, RANDOM() * @map.totalPixelHeight)
      if @end != @start
        @findPath()
  findPath: ()->
    if !@scheduled
      that = @
      @pathingQueue.schedule(@_entity, @end, (waypoints)->
        if waypoints.length > 0
          sprite = that.sprite = new PIXI.Graphics()
          sprite.lineStyle(2, rgb(0,255,0), 0.5)
          sprite.moveTo(waypoints[0].center.x, waypoints[0].center.y)
          for waypoint in waypoints 
            sprite.lineTo(waypoint.center.x, waypoint.center.y)
          that.game.addChild(sprite)
          that.reset = false
          that.waypoints = waypoints
        if that.end.length > 0
          that.end = that.map.get(that.map.totalPixelWidth - 1, RANDOM() * that.map.totalPixelHeight)
          that.resetPath()
        that.scheduled = false)
      @scheduled = true
      @remove()
  resetPath: ()->
    @reset = true
#    if @waypoints.length > 1
#      @waypoints[1]
#      waypoints = TileMap.AStar(@start, @waypoints[1], cost)
#      if waypoints.length > 0
#        waypoints.shift()
#        waypoints.shift()
#        @waypoints = waypoints.concat(@waypoints)
  remove: ()->
    if @sprite?
      @game.removeChild(@sprite)
      @sprite = null
  setTile: (tile)->
    @start = tile)
.sync('waypoints')
.observes(setTile: 'tile')
.listensTo('remove', 'resetPath')

Sentai.componentize(class ShootsTarget extends DecisionMaker
  BulletClass: null
  collider: null
  position: null
  map: null
  game: null
  targets: null
  cooldown: 1000
  cooldownCounter: 0
  bulletSpeed: 500
  constructor: (options)->
    @BulletClass = options.BulletClass
    @map = options.map
    @game = options.game
    @bulletSpeed = options.bulletSpeed || @bulletSpeed
    @collider = options.collider
  setPosition: (position)->
    @position = position
  setTargets: (targets)->
    @targets = targets
  think: (dt)->
    if @cooldownCounter <= 0
      position = @position
      if @targets? && @targets.length > 0 && position?
        target = @targets[0] 
        new @BulletClass(
          color: rgb(255,255,32)
          x: position.x
          y: position.y
          velocity: target.position.sub(position).normalize().multiplyByScalar(@bulletSpeed)
          radius: 4
          map: @map
          collider: @collider
          game: @game)
        @cooldownCounter = 1000
    else
      @cooldownCounter -= dt)          
.observes(
  setPosition: 'position'
  setTargets: 'targets')

Sentai.componentize(class KillWhenNotVisible
  game: null
  position: null
  constructor: (options)->
    @game = options.game
  setPosition: (position)->
    @position = position
  tick: ()->
    game = @game
    position = @position
    @_entity.remove() if game? && (position.x > game.width || position.x < 0 || position.y > game.height || position.y < 0))
.observes(setPosition: 'position')
.listensTo('tick')

# Sprite continuously syncs to a position
Sentai.componentize(class Sprite
  sprite:
    x: 0
    y: 0
  constructor: (options)->
    @sprite = options.sprite || @sprite
  setPosition: (position)->
    if @sprite?
      @sprite.x = FLOOR(position.x)
      @sprite.y = FLOOR(position.y))
.sync('sprite')
.observes(setPosition: 'position')

class GraphicalPlaceholder extends Sprite
  color: rgb(255,255,255)
  radius: 10
  constructor: (options)->
    @color = options.color || @color
    @radius = options.radius || @radius
    sprite = new PIXI.Graphics()
    
    sprite.beginFill(@color)
    sprite.drawCircle(0, 0, @radius)

    #end the fill
    sprite.endFill()

    super(sprite: sprite)

module.exports = 
  GameFunctions: GameFunctions
  StaticObject: StaticObject
  MovingObject: MovingObject
  StaticTileObject: StaticTileObject
  MovingTileObject: MovingTileObject
  KillWhenNotVisible: KillWhenNotVisible
  MovesAroundRandomly: MovesAroundRandomly
  GraphicalPlaceholder: GraphicalPlaceholder
  Ranges:
    FriendlyRange: FriendlyRange
  Bodies:
    FriendlyBullet: FriendlyBullet
    FriendlyBody: FriendlyBody
    EnemyBody: EnemyBody
  ShootsTarget: ShootsTarget