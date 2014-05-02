Sentai = require 'sentai'
Components = require './game-components'

class Placeholder extends Sentai.entity(
  Components.GameFunctions
  Components.MovingTileObject
  Components.Bodies.EnemyBody
  Components.KillWhenNotVisible
  Components.MovesAroundRandomly
  Components.GraphicalPlaceholder)

class PlaceholderTower extends Sentai.entity(
  Components.GameFunctions
  Components.StaticTileObject
  Components.Bodies.FriendlyBody
  Components.Ranges.FriendlyRange
  Components.ShootsTarget
  Components.GraphicalPlaceholder)

class PlaceholderBullet extends Sentai.entity(
  Components.GameFunctions
  Components.MovingObject
  Components.Bodies.FriendlyBullet
  Components.KillWhenNotVisible
  Components.GraphicalPlaceholder)

module.exports =
  Placeholder: Placeholder
  PlaceholderTower: PlaceholderTower
  PlaceholderBullet: PlaceholderBullet