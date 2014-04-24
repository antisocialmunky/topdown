Sentai = require 'sentai'
Menagerie = require 'menagerie'
ADT = Menagerie.ADT
Collidable = Menagerie.Collider.Collidable

Vector2D = ADT.Vector2D
Bounds = ADT.Bounds

rgb = require('./utils').rgb

FLOOR = Math.floor
ROUND = Math.round
SQRT = Math.sqrt

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
  map: null
  constructor: (options)->
    @map = options.map
    @setPosition(new Vector2D
      x: options.x
      y: options.y)
  setPosition: (position)->
    @position = position
    #if @map?
      #@map.add(@_entity)
    )
.sync('position')

Sentai.componentize(class MovingObject extends StaticObject
  velocity: null
  constructor: (options)->
    super
    @velocity = options.velocity || new Vector2D
  tick: (dt)->
    @position = @position.add(@velocity.multiplyByScalar(dt/1000))
  setVelocity: (velocity)->
    @velocity = velocity)
.sync('position', 'velocity')
.observes(
  setPosition: 'position'
  setVelocity: 'velocity')
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
  think: ()->
    @targets = []
  collide: (object1, object2)->
    @targets.push(object2))
.sync('rangeRadius', 'targets')
.observes(setSprite: 'sprite')
.listensTo('think')

Sentai.componentize(class FriendlyRange extends Range
  constructor: (options)->
    super(options,
      layer: 'friendly-range'
      layersToCollide: ['enemy']
      game: options.game
      collider: options.collider))

Sentai.componentize(class DecisionMaker
  think: ()->)
.listensTo('think')

Sentai.componentize(class MoveRightAtConstantSpeed extends DecisionMaker
  speed: 2
  velocity: null
  constructor: (options)->
    @speed = options.speed || @speed
  think: ()->
    @velocity.x = @speed
    @velocity.y = 0
  setVelocity: (velocity)->
    @velocity = velocity)
.observes(setVelocity: 'velocity')

Sentai.componentize(class ShootsTarget
  BulletClass: null
  collider: null
  position: null
  game: null
  targets: null
  cooldown: 1000
  cooldownCounter: 0
  bulletSpeed: 1000
  constructor: (options)->
    @BulletClass = options.BulletClass
    @game = options.game
    @bulletSpeed = options.bulletSpeed || @bulletSpeed
    @collider = options.collider
  setPosition: (position)->
    @position = position
  setTargets: (targets)->
    @targets = targets
  tick: (dt)->
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
          collider: @collider
          game: @game)
        @cooldownCounter = 1000
    else
      @cooldownCounter -= dt)          
.observes(
  setPosition: 'position'
  setTargets: 'targets')
.listensTo('tick')

Sentai.componentize(class KillWhenNotVisible
  game: null
  position: null
  constructor: (options)->
    @game = options.game
  setPosition: (position)->
    @position = position
  tick: ()->
    @_entity.remove() if @game? && (@position.x > @game.width || @position.x < 0 || @position.y > @game.height || @position.y < 0))
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
      @sprite.x = ROUND(position.x)
      @sprite.y = ROUND(position.y))
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
  KillWhenNotVisible: KillWhenNotVisible
  MoveRightAtConstantSpeed: MoveRightAtConstantSpeed
  GraphicalPlaceholder: GraphicalPlaceholder
  Ranges:
    FriendlyRange: FriendlyRange
  Bodies:
    FriendlyBullet: FriendlyBullet
    FriendlyBody: FriendlyBody
    EnemyBody: EnemyBody
  ShootsTarget: ShootsTarget