koa = require 'koa'
route = require 'koa-route'

feeds = require './controller/feeds-manager'
app = koa()


provider_avaliable=['ameblo','blogspot']


app.use route.post('/api/feeds',feeds.add)
app.use route.get('/feeds/:id',feeds.get)


app.listen 3113
