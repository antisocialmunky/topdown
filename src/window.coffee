$ = require 'jquery'

module.exports = 
  PORTRAIT: 0
  LANDSCAPE: 1
  orientation: ()->
    return if window.innerWidth > window.innerHeight then LANDSCAPE else PORTRAIT
  scale: (size)->
    widthRatio = window.innerWidth / size.width
    heightRatio = window.innerHeight / size.height

    return if widthRatio < heightRatio then {x: widthRatio, y: widthRatio} else {x: heightRatio, y:heightRatio} 