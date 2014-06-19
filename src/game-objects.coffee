Sentai = require 'sentai'
Components = require './game-components'

class Placeholder extends Sentai.entity(
  Components.GameFunctions
  Components.Health
  Components.Motion.MovingTileObject
  Components.Collision.EnemyMelee
  Components.Behaviors.KillWhenNotVisible
  Components.Behaviors.MovesAroundRandomly
  Components.Graphics.GraphicalPlaceholder)
  constructor: (options)->
    options.type = ['mover', 'enemy']
    super

class PlaceholderWall extends Sentai.entity(
  Components.GameFunctions
  Components.Health
  Components.Motion.StaticTileObject
  Components.Collision.FriendlyBody
  Components.Graphics.WallPlaceholder)
  constructor: (options)->
    options.type = ['structure', 'wall']
    super

class PlaceholderTower extends Sentai.entity(
  Components.GameFunctions
  Components.Health
  Components.Motion.StaticTileObject
  Components.Collision.FriendlyBody
  Components.Ranges.FriendlyRange
  Components.Behaviors.ShootsTarget
  Components.Graphics.TowerPlaceholder)
  constructor: (options)->
    options.type = ['structure', 'tower']
    super

class PlaceholderBullet extends Sentai.entity(
  Components.GameFunctions
  Components.Motion.MovingObject
  Components.Collision.FriendlyBullet
  Components.Behaviors.KillWhenNotVisible
  Components.Graphics.GraphicalPlaceholder)

class PlaceholderChapel extends Sentai.entity(
  Components.GameFunctions
  Components.Health
  Components.Motion.StaticTileObject
  Components.Collision.FriendlyBody
  Components.Graphics.GraphicalPlaceholder)
  constructor: (options)->
    options.type = ['structure', 'chapel']
    super

module.exports =
  Placeholder: Placeholder
  PlaceholderWall: PlaceholderWall
  PlaceholderTower: PlaceholderTower
  PlaceholderBullet: PlaceholderBullet
  PlaceholderChapel: PlaceholderChapel