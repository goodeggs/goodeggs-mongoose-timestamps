require 'mocha-sinon'
expect = require('chai').expect

timestamps = require '..'
mongoose = require 'mongoose'
clock = require 'node-clock'

TestTimestamps = null
TestTimestampsWithoutIndexes = null
TestTimestampsWithCustomizedIndexes = null

describe 'timestamps', ->

  # Ensure we are starting with a brand-new database
  before (done) ->
    mongoose.connect 'mongodb://localhost/mongoose_timestamps', (err) ->
      return done(err) if err?

      mongoose.connection.db.dropDatabase (err) ->
          return done(err) if err?

          schema = new mongoose.Schema
            data: String
          schema.plugin timestamps
          TestTimestamps = mongoose.model('TestTimestamps', schema)

          schemaWithoutIndexes =
            schema = new mongoose.Schema
              data: String
          schemaWithoutIndexes.plugin timestamps, createIndexes: false
          TestTimestampsWithoutIndexes = mongoose.model('TestTimestampsWithoutIndexes', schemaWithoutIndexes)

          schemaWithCustomizedIndexes =
            schema = new mongoose.Schema
              data: String
          schemaWithCustomizedIndexes.plugin timestamps, createIndexes: {createdAt: -1}
          TestTimestampsWithCustomizedIndexes = mongoose.model('TestTimestampsWithCustomizedIndexes', schemaWithCustomizedIndexes)

          done()

  describe 'create', ->

    it 'sets timestamps', (done) ->
      TestTimestamps.create {}, (err, created) ->
        expect(created.createdAt instanceof Date).to.be.true
        expect(created.updatedAt instanceof Date).to.be.true
        expect(created.createdAt).to.eql(created.updatedAt)
        done(err)

    it 'creates updatedAt index by default', (done) ->
      TestTimestamps.collection.getIndexes (err, indexes) ->
        expect(indexes.timestamp_created_at).to.not.be.ok
        expect(indexes.timestamp_updated_at).to.be.ok
        done(err)

    it 'does not create indexes if disabled', (done) ->
      TestTimestampsWithoutIndexes.collection.getIndexes (err, indexes) ->
        expect(indexes.timestamp_created_at).to.not.be.ok
        expect(indexes.timestamp_updated_at).to.not.be.ok
        done(err)

    it 'customizes indexes', (done) ->
      TestTimestampsWithCustomizedIndexes.collection.getIndexes (err, indexes) ->
        expect(indexes.timestamp_created_at).to.be.ok
        expect(indexes.timestamp_updated_at).to.not.be.ok
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
