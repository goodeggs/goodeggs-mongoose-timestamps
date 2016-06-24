require 'mocha-sinon'
expect = require('chai').expect

timestamps = require '..'
mongoose = require 'mongoose'
clock = require 'node-clock'

mongoose.connect('mongodb://localhost/mongoose_timestamps')

schema = new mongoose.Schema
  data: String
schema.plugin timestamps
TestTimestamps = mongoose.model('TestTimestamps', schema)

schemaWithoutIndices =
  schema = new mongoose.Schema
    data: String
schemaWithoutIndices.plugin timestamps, createIndices: false
TestTimestampsWithoutIndices = mongoose.model('TestTimestampsWithoutIndices', schemaWithoutIndices)

schemaWithCustomizedIndices =
  schema = new mongoose.Schema
    data: String
schemaWithCustomizedIndices.plugin timestamps, createIndices: {updatedAt: -1}
TestTimestampsWithCustomizedIndices = mongoose.model('TestTimestampsWithCustomizedIndices', schemaWithCustomizedIndices)


describe 'timestamps', ->

  beforeEach (done) ->
    TestTimestamps.remove(done)

  describe 'create', ->

    it 'sets timestamps', (done) ->
      TestTimestamps.create {}, (err, created) ->
        expect(created.createdAt instanceof Date).to.be.true
        expect(created.updatedAt instanceof Date).to.be.true
        expect(created.createdAt).to.eql(created.updatedAt)
        done(err)

    it 'creates indices by default', (done) ->
      TestTimestamps.collection.getIndexes (err, indexes) ->
        expect(indexes.timestamp_created_at).to.be.ok
        expect(indexes.timestamp_updated_at).to.be.ok
        done(err)

    it 'does not create indices if disabled', (done) ->
      TestTimestampsWithoutIndices.collection.getIndexes (err, indexes) ->
        expect(indexes.timestamp_created_at).to.not.be.ok
        expect(indexes.timestamp_updated_at).to.not.be.ok
        done(err)

    it 'customizes indices', (done) ->
      TestTimestampsWithCustomizedIndices.collection.getIndexes (err, indexes) ->
        expect(indexes.timestamp_created_at).to.not.be.ok
        expect(indexes.timestamp_updated_at).to.be.ok
        done(err)

  describe 'update', ->
    created = null

    beforeEach (done) ->
      @sinon.stub(clock, 'now') unless clock.now.returns
      clock.now.returns clock.pacific '2012-04-01 12:00'
      TestTimestamps.create {}, (err, obj) ->
        created = obj
        expect(created.createdAt).to.eql new Date(clock.pacific '2012-04-01 12:00')
        done(err)

    it 'sets updatedAt', (done) ->
      clock.now.returns clock.pacific '2012-04-01 12:01'
      created.data = 'some new value'
      created.save (err) ->
        expect(created.updatedAt).to.eql new Date(clock.pacific '2012-04-01 12:01')
        done(err)

    # this is especially important for embedded docs whose updatedAt shouldn't change unless the embedded doc has a change
    it 'leaves updatedAt unset without any value changes', (done) ->
      clock.now.returns clock.pacific '2012-04-01 12:01'
      created.save (err) ->
        expect(created.updatedAt).to.eql(created.createdAt)
        done(err)
