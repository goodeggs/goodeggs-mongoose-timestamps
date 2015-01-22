clock = require 'node-clock'

module.exports = (schema, options) ->
  schema.add
    updatedAt: {type: Date}
    createdAt: {type: Date}

  schema.pre 'save', (next) ->
    now = clock.now()
    @createdAt = now if @isNew
    @updatedAt = now if @isNew or @isModified()
    next()

