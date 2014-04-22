Sentai = require 'sentai'
Components = require './game-components'

Placeholder = Sentai.entity(
  Components.GameFunctions
  Components.CollisionBody
  Components.MovingObject
  Components.KillWhenNotVisible
  Components.MoveRightAtConstantSpeed
  Components.GraphicalPlaceholder)

PlaceholderTower = Sentai.entity(
  Components.GameFunctions
  Components.CollisionBody
  Components.StaticObject
  Components.Range
  Components.ShootsTarget
  Components.GraphicalPlaceholder)

PlaceholderBullet = Sentai.entity(
  Components.GameFunctions
  Components.Bullet
  Components.MovingObject
  Components.KillWhenNotVisible
  Components.GraphicalPlaceholder)

module.exports =
  Placeholder: Placeholder
  PlaceholderTower: PlaceholderTower
  PlaceholderBullet: PlaceholderBullet