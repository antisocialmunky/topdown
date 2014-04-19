var express = require('express'),
    app = express();

var config = {
  // INFRA
  "/stats.js": {
    file: "/vendor/stats.js/src/Stats.js"
  },
  "/pixi.js": {
    file: "/vendor/pixi.js/pixi.dev.js"
  },
  "/normalize.css": {
    file: "/vendor/normalize/normalize.css"
  },
  // TESTING
  // PUBLIC
  "/": {
    dir: "/public"
  },
  "/assets": {
    dir: "/assets"
  },
};

this.use = function(routes) {
  for(var route in routes) {
    if (routes.hasOwnProperty(route)) {
      var routeConfig = routes[route];
      console.log(route);
      console.log(routeConfig);
      if(routeConfig.file) {
        (function(file) {
          app.use(route, function(req, res){ res.sendfile(__dirname+file); });
        })(routeConfig.file);
      } else if (routeConfig.dir) {
        (function(dir) {
          app.use(route, express.static(__dirname+dir));
        })(routeConfig.dir);
        var dir = routeConfig.dir;
      }
    }
  }
};

this.use(config);

app.use('/app.js', require('requisite').middleware({
  entry: __dirname + '/src/index.js'
}));

app.listen(process.env.PORT || 8080);
