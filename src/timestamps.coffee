###
  Adds createdAt and updatedAt attributes to the document and automatically sets them on create and updates.
  Uses built-in Mongoose support for creating and updating timestamps (http://mongoosejs.com/docs/guide.html#timestamps).

  By default creates indexes for both attributes. Indexing behavior can be customized with plugin options:

  timestamps = require 'goodeggs-mongoose-timestamps'

  # Creates indexes for updatedAt by default
  schema.plugin timestamps

  # Does not create indexes
  schema.plugin timestamps, createIndexes: false

  # Only create createdAt index, descending order
  schema.plugin timestamps, createIndexes: {createdAt: -1}
###
module.exports = (schema, options = {}) ->
  # Default is to create index on updatedAt
  createIndexes = options.createIndexes
  createIndexes ?= true

  if createIndexes is true
    createIndexes = {updatedAt: 1}

  # Use built-in Mongoose support for timestamps (http://mongoosejs.com/docs/guide.html#timestamps)
  # First available in Mongoose 4.4.7 (https://github.com/Automattic/mongoose/blob/master/History.md#447--2016-03-11)
  schema.set 'timestamps', true

  # Index createdAt, but only when the schema is the root schema (not embedded in another document)
  if createIndexes?.createdAt
    order = createIndexes.createdAt in [-1, 1] and createIndexes.createdAt or 1
    schema.on 'init', (modelCls) ->
      modelCls.collection.ensureIndex { createdAt: order }, { background: true}

  # Index updatedAt, but only when the schema is the root schema (not embedded in another document)
  if createIndexes?.updatedAt
    order = createIndexes.updatedAt in [-1, 1] and createIndexes.updatedAt or 1
    schema.on 'init', (modelCls) ->
      modelCls.collection.ensureIndex { updatedAt: order }, { background: true }

