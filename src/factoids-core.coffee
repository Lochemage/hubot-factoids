class Factoids
  constructor: (@robot) ->
    if @robot.brain?.data?
      @data = @robot.brain.data.factoids ?= {}

    @robot.brain.on 'loaded', =>
      @data = @robot.brain.data.factoids ?= {}

  set: (key, value, who, resolveAlias) ->
    key = key.trim()
    value = value.trim()
    fact = @get key, resolveAlias

    if typeof fact is 'object'
      fact.history ?= []
      hist =
        date: Date()
        editor: who
        oldValue: fact.value
        newValue: value

      fact.history.push hist
      fact.value = value
      if fact.forgotten? then fact.forgotten = false
    else
      fact =
        value: value
        popularity: 0

    @data[key.toLowerCase()] = fact

  add: (key, value, who, resolveAlias) ->
    fact = @get key, resolveAlias
    fact = fact.value + ", and is also " + value
    @set key, fact, who, resolveAlias

  get: (key, resolveAlias = true) ->
    fact = @data[key.toLowerCase()]
    alias = fact?.value?.match /^@([^@].+)$/i
    if resolveAlias and alias?
      fact = @get alias[1]
    fact

  has: (key) ->
    if key of @data
      true
    else false

  search: (str) ->
    keys = Object.keys @data

    keys.filter (a) =>
      if @data[a].forgotten
        return false
      value = @data[a].value
      value.indexOf(str) > -1 || a.indexOf(str) > -1

  ref: (fact, aliases) ->
    aliasKey = fact.value.match(/^@([^@].+)$/i)
    if aliasKey
      aliases.push key
      key = aliasKey[1]
      # Check for multi-tiered aliases.
      return @ref @data[key], aliases
    {
      aliases: aliases
      value: fact.value
      key: key
    }

  list: ->
    map = {}
    keys = Object.keys @data
    key = ''

    i = 0
    while i < keys.length
      key = keys[i]
      fact = @data[key]
      if fact.forgotten
        ++i
        continue
      data = @ref fact, []
      if data.key
        key = data.key

      if !map[key]
        map[key] =
          aliases: []
          value: ''
      map[key].aliases = map[key].aliases.concat(data.aliases)
      map[key].value = data.value
      ++i
    result = []
    for name of map
      str = map[name]
      if map[name].aliases.length
        str += ' (' + map[key].aliases.join(', ') + ')'
      result.push str
    result

  forget: (key) ->
    fact = @get key

    if fact
      fact.forgotten = true

  remember: (key) ->
    fact = @get key
    if fact
      fact.forgotten = false
    fact

  drop: (key) ->
    key = key.toLowerCase()
    if @has key
      delete @data[key]
    else false

module.exports = Factoids
