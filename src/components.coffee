Sentai = require 'sentai'

#should be in require './utils'
rgb = (r, g, b) ->
  return FLOOR(b) | FLOOR(g << 8) | FLOOR(r << 16) 

Sentai.componentize(class GameFunctions
  game: null
  constructor: (options)->
    @game = options.game
  remove: ()->
    @game.entityRemovalQueue.push(@_entity))
.listensTo('remove')

Sentai.componentize(class StaticObject
  position:
    x: 0
    y: 0
  constructor: (options)->
    @position.x = options.x || @x
    @position.y = options.y || @y
  setPosition: (position)->
    @position = position)
.sync('position')

Sentai.componentize(class MovingObject extends StaticObject
  velocity:
    x: 0
    y: 0
  constructor: (options)->
    super
    @velocity = options.velocity
  tick: (dt)->
    @x += velocity.x / dt
    @y += velocity.y / dt
  setVelocity: (velocity)->
    @velocity = velocity)
.sync('position', 'velocity')
.observes(setPosition: ['position'], setVelocity: ['velocity'])

class DecisionMaker
  think: ()->

Sentai.componentize(class MoveRightAtConstantSpeed extends DecisionMaker
  think: ()->
    @velocity = 
      x: options.speed || 2
      y: 0)
.sync('velocity')
.listensTo('think')

# Sprite continuously syncs to a position
class Sprite
  sprite: null
  constructor: (options)->
    sprite = @options.sprite
  setPosition: (position)->
    @_position = position
  tick: ()->
    @sprite.x = @_position.x
    @sprite.y = @_position.y

Sentai.componentize(class GraphicalPlaceholder extends Sprite
  color: rgb(255,255,255)
  radius: 10
  constructor: (options)->
    @color = options.color? || @color
    @radius = options.radius? || @radius
    sprite = PIXI.Graphics
    super(sprite: sprite))
.observes(setPosition: ['position'])

module.exports = 
  GameFunctions: GameFunctions
  StaticObject: StaticObject
  MovingObject: MovingObject
  MoveRightAtConstantSpeed: MoveRight
  GraphicalPlaceholder: GraphicalPlaceholder