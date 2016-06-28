clock = require 'node-clock'

###
  Adds createdAt and updatedAt attributes to the document and automatically sets them on create and updates.

  By default creates indexes for both attributes. Indexing behavior can be customized with plugin options:

  timestamps = require 'goodeggs-mongoose-timestamps'

  # Creates indexes for updatedAt by default
  schema.plugin timestamps

  # Does not create indexes
  schema.plugin timestamps, createIndexes: false

  # Only create createdAt index, descending order
  schema.plugin timestamps, createIndexes: {createdAt: -1}
###
module.exports = (schema, {createIndexes} = {}) ->
  # Default is to create both indexes
  createIndexes ?= true

  if createIndexes is true
    createIndexes = {updatedAt: 1}

  schema.add
    updatedAt: {type: Date}
    createdAt: {type: Date}

  if createIndexes?.createdAt
    order = createIndexes.createdAt in [-1, 1] and createIndexes.createdAt or 1
    schema.index {createdAt: order}, name: 'timestamp_created_at'
  if createIndexes?.updatedAt
    order = createIndexes.updatedAt in [-1, 1] and createIndexes.updatedAt or 1
    schema.index {updatedAt: order}, name: 'timestamp_updated_at'


  schema.pre 'save', (next) ->
    now = clock.now()
    @createdAt = now if @isNew
    @updatedAt = now if @isNew or @isModified()
    next()

