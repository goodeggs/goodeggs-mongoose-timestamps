clock = require 'node-clock'

###
  Adds createdAt and updatedAt attributes to the document and automatically sets them on create and updates.

  By default creates indices for both attributes. Indexing behavior can be customized with plugin options:

  timestamps = require 'goodeggs-mongoose-timestamps'

  # Creates indices for both attributes by default
  schema.plugin timestamps

  # Does not create indices
  schema.plugin timestamps, createIndices: false

  # Only create updatedAt index, descending order
  schema.plugin timestamps, createIndices: {updatedAt: -1}
###
module.exports = (schema, {createIndices} = {}) ->
  # Default is to create both indices
  createIndices ?= true

  if createIndices is true
    createIndices = {createdAt: 1, updatedAt: 1}

  schema.add
    updatedAt: {type: Date}
    createdAt: {type: Date}

  if createIndices?.createdAt
    order = createIndices.createdAt in [-1, 1] and createIndices.createdAt or 1
    schema.index {createdAt: order}, name: 'timestamp_created_at'
  if createIndices?.updatedAt
    order = createIndices.updatedAt in [-1, 1] and createIndices.updatedAt or 1
    schema.index {updatedAt: order}, name: 'timestamp_updated_at'


  schema.pre 'save', (next) ->
    now = clock.now()
    @createdAt = now if @isNew
    @updatedAt = now if @isNew or @isModified()
    next()

