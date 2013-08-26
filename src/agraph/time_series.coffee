util = require 'util'

sort_ints = (list) ->
  list.map((n) -> parseInt(n)).sort((a, b) -> a - b)

class DataCollection
  constructor: ->
    # name -> { timestamp: value }
    @data = {}

  # add data of the form [ [x, y]... ] or [ {x, y}... ]
  addPoints: (name, points) ->
    @data[name] or= {}
    if Object.prototype.toString.call(points[0]).match(/Array/)?
      for [ ts, y ] in points then @data[name][ts] = y
    else
      for p in points then @data[name][p.x] = p.y

  toTable: ->
    tset = {}
    for name, points of @data then for ts, v of points then tset[ts] = true
    timestamps = sort_ints(Object.keys(tset))
    console.log "so far #{timestamps}"
    if timestamps.length > 1
      # calculate smallest interval, and fill in gaps so all intervals are equal.
      deltas = [1 ... timestamps.length].map (i) -> timestamps[i] - timestamps[i - 1]
      console.log "deltas #{deltas}"
      interval = sort_ints(deltas)[0]
      i = 1
      while i < timestamps.length
        if timestamps[i] - timestamps[i - 1] > interval
          console.log "boo."
          timestamps.push timestamps[i - 1] + interval
          timestamps = sort_ints(timestamps)
        else
          i += 1
    names = Object.keys(@data)
    datasets = {}
    for name in names then datasets[name] = []
    for ts in timestamps then for name in names then datasets[name].push @data[name][ts]
    new DataTable(timestamps, datasets)
 

class DataTable
  # timestamps is a sorted list of time values, at equal intervals.
  # datasets is { name -> [values...] }, where the values correspond 1-to-1 with the timestamps.
  constructor: (@timestamps, @datasets) ->


# a set of (x, y) points that make up a line to be graphed.
# the x range must cover the entire graph, but y values of "undefined" (or null) are allowed.
# the x range must contain at least 2 values.
class Dataset
  constructor: (@points) ->
    if Object.prototype.toString.call(@points[0]).match(/Array/)?
      @points = @points.map ([ x, y ]) -> { x, y }
    @points.sort (a, b) -> a.x - b.x
    @last = @points.length - 1
  
  toString: ->
    point_strings = @points.map (p) -> "(#{p.x}, #{p.y})"
    "Dataset(#{point_strings.join(', ')})"

  # turn our N points into 'count' points, anchored on each end, but interpolated in the middle.
  # returns a new Dataset with the new values.
  interpolate_to: (count) ->
    if count * 2 <= @points.length then return @compact_to(count)
    delta_x = (@points[@last].x - @points[0].x) / (count - 1)
    new_points = [ @points[0] ]
    for i in [1 ... count]
      x = @points[0].x + delta_x * i
      new_points.push @interpolate_for_x(x)
    new Dataset(new_points)

  # like interpolate, but if we are creating fewer points, we want to compute running averages.
  compact_to: (count) ->
    delta_x = (@points[@last].x - @points[0].x) / (count - 1)
    new_points = [ ]
    for i in [0 ... count]
      x = @points[0].x + delta_x * i
      # first, interpolate Y as it would exist on the left & right edges of our delta_x-width zone.
      x0 = x - delta_x / 2
      x1 = x + delta_x / 2
      [ left0, right0 ] = @fenceposts_for_x(x0)
      [ left1, right1 ] = @fenceposts_for_x(x1)
      p_left = @interpolate_for_x(x0, left0, right0)
      p_right = @interpolate_for_x(x1, left1, right1)
      # sum the area under the points from p_left to p_right
      area = 0
      width = 0
      ok = false
      for j in [left0 ... right1]
        p0 = if j == left0 then p_left else @points[j]
        p1 = if j + 1 == right1 then p_right else @points[j + 1]
        # area is delta-x * average(p0.y, p1.y)
        if p0.y? or p1.y? then ok = true
        area += (p1.x - p0.x) * ((p0.y or 0) + (p1.y or 0)) / 2
        width += (p1.x - p0.x)
      y = if ok then area / width else null
      new_points.push { x, y }
    new Dataset(new_points)

  # ----- internals:

  # interpolate a new y value for the given x value
  interpolate_for_x: (x, left = null, right = null) ->
    if not left?
      [ left, right ] = @fenceposts_for_x(x)
    x = Math.min(Math.max(x, @points[left].x), @points[right].x)

    if (not @points[left].y?) or (not @points[right].y?)
      y = null
    else if left == right
      y = @points[left].y
    else
      delta_y = @points[right].y - @points[left].y
      delta_x = @points[right].x - @points[left].x
      y = @points[left].y + delta_y * (x - @points[left].x) / delta_x
    { x, y }

  # figure out the left and right fenceposts for an x
  fenceposts_for_x: (x) ->
    ratio = (x - @points[0].x) / (@points[@last].x - @points[0].x)
    left = Math.max(0, Math.min(@last, Math.floor(ratio * @last)))
    right = Math.max(0, Math.min(@last, Math.ceil(ratio * @last)))
    [ left, right ]





DEFAULT_OPTIONS =
  scale_to_zero: false

class Graph
  constructor: (@width, @height, options) ->

  

exports.DataCollection = DataCollection

exports.Dataset = Dataset
