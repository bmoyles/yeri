should = require 'should'
time_series = require '../src/agraph/time_series'
inspect = require("util").inspect

describe "DataCollection", ->
  it "can sort two datasets", ->
    d = new time_series.DataCollection()
    d.addPoints("errors", [ [ 0, 1 ], [ 10, 0 ], [ 5, 6 ] ])
    d.addPoints("hits", [ [ 5, 11 ], [ 10, 12 ], [ 0, 9 ] ])
    table = d.toTable()
    table.timestamps.should.eql [ 0, 5, 10 ]
    table.datasets.should.eql {
      errors: [ 1, 6, 0 ]
      hits: [ 9, 11, 12 ]
    }

  it "can detect missing timestamps", ->
    d = new time_series.DataCollection()
    d.addPoints("errors", [ [ 0, 1 ], [ 5, 2 ], [ 15, 6 ] ])
    d.addPoints("hits", [ [ 5, 11 ], [ 15, 12 ] ])
    table = d.toTable()
    table.timestamps.should.eql [ 0, 5, 10, 15 ]
    table.datasets.should.eql {
      errors: [ 1, 2, undefined, 6 ]
      hits: [ undefined, 11, undefined, 12 ]
    }

describe "time_series", ->
  describe "can interpolate a dataset", ->
    data1 = new time_series.Dataset [ [ 0, 2 ], [ 3, 5 ], [ 6, 8 ] ]
    data2 = new time_series.Dataset [ [ 5, 100 ], [ 6, 120 ], [ 7, null ], [ 8, 140 ], [ 9, 160 ] ]
    data3 = new time_series.Dataset [ [ 5, 100 ], [ 8, 106 ], [ 11, 112 ], [ 14, 118 ], [ 17, 124 ] ]
    data4 = new time_series.Dataset [
      [ 20, 100 ], [ 22, 110 ], [ 24, 130 ], [ 26, 130 ], [ 28, 120 ], [ 30, 150 ],
      [ 32, 140 ], [ 34, 100 ], [ 36, 130 ]
    ]
    data5 = new time_series.Dataset [
      [ 20, null ], [ 22, null ], [ 24, null ], [ 26, 90 ], [ 28, null ], [ 30, null ]
    ]

    it "one to one", ->
      d = data1.interpolate_to(3)
      d.toString().should.eql(data1.toString())

    it "doubling", ->
      d = data1.interpolate_to(5)
      d.toString().should.eql "Dataset((0, 2), (1.5, 3.5), (3, 5), (4.5, 6.5), (6, 8))"

    it "shrinking", ->
      d = data3.interpolate_to(3)
      d.toString().should.eql "Dataset((5, 100), (11, 112), (17, 124))"

    it "with missing segment", ->
      d = data2.interpolate_to(9)
      d.toString().should.eql "Dataset((5, 100), (5.5, 110), (6, 120), (6.5, null), (7, null), " +
        "(7.5, null), (8, 140), (8.5, 150), (9, 160))"

    it "fractional expansion", ->
      d = data1.interpolate_to(4)
      d.toString().should.eql "Dataset((0, 2), (2, 4), (4, 6), (6, 8))"

    it "fractional contraction", ->
      d = data3.interpolate_to(4)
      d.toString().should.eql "Dataset((5, 100), (9, 108), (13, 116), (17, 124))"

    it "compacts", ->
      d = data4.compact_to(3)
      d.toString().should.eql "Dataset((20, 112.5), (28, 133.75), (36, 117.5))"

    it "doesn't compact away to nothing", ->
      d = data5.compact_to(3)
      d.toString().should.eql "Dataset((20, null), (25, 31.5), (30, null))"
