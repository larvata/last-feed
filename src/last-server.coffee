
# background rss sprider
TaskManager=require('./lib/taskManager')
taskManager=new TaskManager()

# server
koa = require 'koa'
route = require 'koa-route'

feeds = require './controller/feeds-controller'
app = koa()


provider_avaliable=['ameblo','blogspot']


app.use route.post('/api/feeds',feeds.add)
app.use route.get('/api/feeds',feeds.getAll)
app.use route.get('/feeds/:id',feeds.get)


app.listen 3113
