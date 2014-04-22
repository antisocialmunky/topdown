Sentai = require 'sentai'
Vector2D = require './c_vector2d'
Rectangle = require('menagerie')

rgb = require('./c_utils').rgb

FLOOR = Math.floor
ROUND = Math.round
SQRT = Math.sqrt

Sentai.componentize(class GameFunctions
  game: null
  constructor: (options)->
    @game = options.game
    @game.add(@_entity)
  addSprite: (sprite)->
    @game.addChild(sprite)
  remove: ()->
    @game.remove(@_entity))
.observes(addSprite: 'sprite')
.listensTo('remove')

Sentai.componentize(class StaticObject
  position: null
  constructor: (options)->
    @position = new Vector2D
      x: options.x
      y: options.y
  setPosition: (position)->
    @position = position)
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

class DecisionMaker
  think: ()->

Sentai.componentize(class CollisionBody
  radius: 0
  position: null
  constructor: (options)->
    @radius = options.radius || @radius
  checkForCollision: (entity)->
    @collide(entity) if entity.radius? && entity.position? && @position.sub(entity.position).length() <= @radius + entity.radius
  collide: ()->
  setPosition: (position)->
    @position = position)
.sync('radius')          
.observes(setPosition: 'position')

Sentai.componentize(class Bullet extends CollisionBody
  filter: null
  game: null
  constructor: (options)->
    @game = options.game
    @filter = options.filter
    super
  tick: ()->
    for entity in @game.entityList
      if @filter(entity)
        @checkForCollision(entity)
  collide: (entity)->
    @_entity.remove()
    entity.remove())
.listensTo('tick')

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
.listensTo('think')

Sentai.componentize(class ShootsTarget extends DecisionMaker
  BulletClass: null
  position: null
  game: null
  targets: null
  cooldown: 1000
  cooldownCounter: 0
  filter: null
  bulletSpeed: 1000
  constructor: (options)->
    @BulletClass = options.BulletClass
    @game = options.game
    @filter = options.filter
    @bulletSpeed = options.bulletSpeed || @bulletSpeed
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
          filter: @filter
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

Sentai.componentize(class Range
  rangeColor: rgb(255,0,0)
  rangeRadius: 100
  rangeSprite: null
  targets: null
  game: null
  filter: null
  constructor: (options)->
    @game = options.game
    @filter = options.filter
    @rangeColor = options.rangeColor || @rangeColor
    @rangeRadius = options.rangeRadius || @rangeRadius
    @targets = []
    rangeSprite = @rangeSprite = new PIXI.Graphics()
    
    rangeSprite.lineStyle(1, @rangeColor)
    rangeSprite.drawCircle(0, 0, @rangeRadius)
  setSprite: (sprite)->
    sprite.addChild(@rangeSprite)
  tick: ()->
    if @filter?
      @targets.length = 0
      myEntity = @_entity
      for entity in @game.entityList
        if entity != myEntity && entity.position? && @filter(entity)
          x = myEntity.position.x - entity.position.x
          y = myEntity.position.y - entity.position.y
          dist = SQRT(x * x + y * y)
          if dist <= @rangeRadius
            @targets.push(entity))
.sync('rangeRadius', 'targets')
.observes(setSprite: 'sprite')
.listensTo('tick')

module.exports = 
  GameFunctions: GameFunctions
  StaticObject: StaticObject
  MovingObject: MovingObject
  KillWhenNotVisible: KillWhenNotVisible
  MoveRightAtConstantSpeed: MoveRightAtConstantSpeed
  GraphicalPlaceholder: GraphicalPlaceholder
  Range: Range
  CollisionBody: CollisionBody
  Bullet: Bullet
  ShootsTarget: ShootsTarget