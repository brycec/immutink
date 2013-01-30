md5 = require 'MD5'
derby = require 'derby'
{get, post, view, ready} = app = derby.createApp module
derby.use(require '../../ui')

OWNER_REGEX = /([\w ]+)#?(.+)?/

## ROUTES ##
get '/', (page) ->
  page.redirect('/i')

get '/:space*', (page, model, params, next) ->
  model.setNull '_ink_remaining', 0
  next()

# Derby routes can be rendered on the client and the server
get '/:space', (page, model, {space}) ->

  model.subscribe "#{space}.inks", (err, inks) ->
    model.ref '_inks', inks.filter().where('id').exists()
    model.setNull '_inks', []

    model.fn '_inks_sorted', '_inks', (inks) ->
      inks.slice().reverse()

    # Render will use the model data as well as an optional context object
    page.render 'index',
      space: space

get '/:space/new', (page, model, {space}) ->
  model.set '_paths', []
  model.set '_submit_ready', false
  page.render 'new',
    space: space

post '/:space/new', (page, model, {space, body: {data_url}}) ->
  id = model.id()
  model.set "#{space}.inks." + id ,
    data_url: data_url
    id: id

  page.redirect "/#{space}"

get '/:space/:inkid', (page, model, {space, inkid}) ->
  model.set '_is_valid', false
  model.subscribe "#{space}.inks.#{inkid}", (err, ink) ->
    model.ref '_ink', ink
    page.render 'ink'
post '/:space/:inkid', (page, model, {space, inkid, body: {owner, name}}) ->
  if not owner or not name then return
  owner_parts = owner.match(OWNER_REGEX)
  if not owner_parts[1] then return
  if owner_parts[2]
    hash = md5(owner_parts[2])
  else
    hash = ''
  model.ref '_ink', "#{space}.inks.#{inkid}"
  model.set '_ink.owner', owner_parts[1]
  model.set '_ink.owner_hash', hash
  model.set '_ink.name', name
  model.incr '_ink_remaining', 25

  page.redirect "/#{space}"




## CONTROLLER FUNCTIONS ##

renderPaths = (segments) ->
  for path in segments
    p = new paper.Path(path)
    p.style =
      strokeColor: 'black'
      strokeWidth: 8

randomShift = (point, amt) ->
  new paper.Point(point.x + (Math.random() - 0.5)*amt,
                   point.y + (Math.random() - 0.5)*amt)

randomColor = (h = Math.random() * 360, s = 0.6, b = 1) ->
  new paper.HsbColor(h,s,b)

renderSlime = (size) ->
  global.slime = p = new paper.Path.Circle paper.view.center, size
  p.position.y += size * 0.25
  p.style =
    strokeColor: 'black'
    strokeWidth: size / 9.1
    fillColor: randomColor()
  console.log p.segments
  p.flatten size
  for segment in p.segments
    segment.point = randomShift(segment.point, size * 0.90)
  p.smooth()  

  eye = new paper.Path.Oval(new paper.Rectangle(randomShift(paper.view.center, size*0.5),
                              new paper.Size(size / 12.1, size / 6.1)))
  eye.position.x += size * 0.1
  eye.fillColor = 'black'
  eye.segments[1].point = randomShift(eye.segments[1].point, size / 24.1)
  eye.segments[3].point = randomShift(eye.segments[3].point, size / 30.1)
  global.eye2 = eye.clone()
  eye2.position.x -= size * 0.5 * Math.random() + (size / 9.1)
  eye2.scale(-1, 1)



ready (model) ->
  @validateAdoption = (e) ->
    owner = document.getElementById('adopt_owner').value
    name = document.getElementById('adopt_name').value
    if not owner or not name then return
    owner_parts = owner.match(OWNER_REGEX)
    if not owner_parts[1] then return
    
    model.set '_is_valid', true


  @newColor = ->
    slime.fillColor = randomColor()
  @inkPlz = ->
    model.incr '_ink_remaining', 20

  @initCanvas = ->
    console.log 'init'
    model.setNull '_paths', []
    path = null

    paper.setup 'theCanvas'
    view = paper.view

    view.draw()
    renderSlime 100

    view.onFrame = ->
      path?.smooth()

    tool = new paper.Tool()
    tool.onMouseDown = (e) ->
      if model.get('_ink_remaining') <= 0 then return

      path = new paper.Path()
      path.style =
        strokeColor: 'black'
        strokeWidth: 6
      path.add e.point
      path.add e.point
      model.incr('_ink_remaining', -1)

    tool.onMouseDrag = (e) ->
      if model.get('_ink_remaining') <= 0 then return
      # this achieves the effect of smooth drawing, while maintaining a distance between new points
      path.lastSegment.point = e.point
      if path.segments[path.segments.length-2].point.getDistance(e.point) > 10
        path.add e.point
        model.incr('_ink_remaining', -1)

    tool.onMouseUp = (e) ->
      if model.get('_ink_remaining') <= 0 then return
      model.set '_submit_ready', false
      raster = paper.project.activeLayer.rasterize()
      model.set '_data_url', raster.image.toDataURL()
      model.set '_submit_ready', true
      raster.remove()

  app.on "render:new", (e) ->
    console.log e
    app.initCanvas()

# helpers
view.fn 'json', (obj) ->
  JSON.stringify obj
view.fn 'debug', (obj) ->
  console.log(obj)
  obj