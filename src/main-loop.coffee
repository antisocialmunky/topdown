$ = require 'jquery'
Game = require './game'
#Utils = require './utils'

$(document).ready(()->

  loader = new PIXI.AssetLoader([
    './assets/GrassTile.png'
    './assets/TowerSprite.png'
    ], false)
  loader.onComplete = ()->
    #create an new instance of a pixi stage
    game = new Game()#Utils.rgb(1, 1, 13))
    game.start()
  loader.load())