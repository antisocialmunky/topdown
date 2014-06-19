Sentai = require './sentai'
Components = require './game-components'

Sentai.componentize(class TileObject extends Components.StaticObject
  tile: null
  constructor: (options)->
    @tile = options.tile
    center = @tile.center
    options.x = center.x
    options.y = center.y
    super(options))

class Tile extends Sentai.entity(
  TileObject
  Components.Sprite)
  constructor: (options)->
    options.type = 'tile'
    super

module.exports =
  Components:
    Tile: Tile