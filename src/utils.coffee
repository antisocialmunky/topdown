FLOOR = Math.floor

module.exports = 
  rgb: (r, g, b) ->
    return FLOOR(b) | FLOOR(g << 8) | FLOOR(r << 16) 