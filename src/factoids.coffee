# Description:
#   A better implementation of factoid support for your hubot.
#   Supports history (in case you need to revert a change), as
#   well as factoid popularity, aliases and @mentions.
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   <factoid>? - Prints the factoid, if it exists.
#   ~<factoid> is <some phrase, link, whatever> - Creates or overwrites a factoid.
#   ~<factoid> is also <some phrase, link, whatever> - Adds another phrase to a factoid.
#   ~<factoid> edit s/expression/replace/gi - Edit an existing factoid.
#   ~<factoid> alias of <factoid> - Add an alternate name for a factoid.
#   ~tell <user> about <factoid> - Tells the user about a factoid, if it exists
#   hubot no, <factoid> is <some phrase, link, whatever> - Replaces the full definition of a factoid
#   hubot forget <factoid> - Forget a factoid.
#   hubot remember <factoid> - Remember a previously forgotten factoid
#   hubot drop <factoid> - Permanently forget a factoid
#   hubot factoids - List all factoids
#
# Author:
#   therealklanni
#   lochemage

Factoids = require './factoids-core'

module.exports = (robot) ->
  factoids = new Factoids robot

  # <factoid>?
  robot.hear /(.+)\?/i, (msg) ->
    fact = factoids.get msg.match[1]
    if fact and not fact.forgotten
      fact.popularity++
      msg.reply msg.match[1] + " is " + fact.value

  # tell <user> about <factoid>
  robot.hear /^~tell (.+?) about (.+)/i, (msg) ->
    fact = factoids.get msg.match[2]
    if fact and not fact.forgotten
      fact.popularity++
      msg.send msg.match[1] + ": " + msg.match[2] + " is " + fact.value

  # <factoid> is also <value>
  # robot.hear /^~(.+?) is also (.+)/i, (msg) ->
  #   [key, value] = [msg.match[1], msg.match[2]]
  #   factoids.add key, value, msg.message.user.name

  # <factoid> edit <value>
  robot.hear /^~(.+?) edit s\/(.+)\/(.+)\/(.*)/i, (msg) ->
    key = msg.match[1]
    re = new RegExp(msg.match[2], msg.match[4])
    fact = factoids.get key
    value = fact?.value.replace re, msg.match[3]

    factoid = factoids.set key, value, msg.message.user.name if value?

    if factoid? and factoid.value?
      msg.reply "OK, #{key} is now #{factoid.value}"
    else
      msg.reply 'Not a factoid'

  # <factoid> is [also] <value>
  robot.hear /^~(.+?) is (.+)/i, (msg) ->
    [key, value] = [msg.match[1], msg.match[2]]

    if match = (/^~(.+?) is also (.+)/i.exec msg.match)
      factoid = factoids.add key, msg.match[2], msg.message.user.name
    else
      factoid = factoids.set key, value, msg.message.user.name

    if factoid.value?
      msg.reply "OK, #{key} is #{factoid.value}"

  # <factoid> alias of <value>
  robot.hear /^~(.+?) alias of (.+)/i, (msg) ->
    [key, target] = [msg.match[1], msg.match[2]]
    who = msg.message.user.name
    msg.reply "OK, aliased #{key} to #{target}" if factoids.set key, "@#{msg.match[2]}", msg.message.user.name, false

  # forget <factoid>
  robot.respond /forget (.+)/i, (msg) =>
    if factoids.forget msg.match[1]
      msg.reply "OK, forgot #{msg.match[1]}"
    else
      msg.reply 'Not a factoid'

  # remember <factoid>
  robot.respond /remember (.+)/i, (msg) =>
    factoid = factoids.remember msg.match[1]
    if factoid? and not factoid.forgotten
      msg.reply "OK, #{msg.match[1]} is #{factoid.value}"
    else
      msg.reply 'Not a factoid'

  # factoids
  robot.respond /factoids/i, (msg) ->
    msg.send factoids.list().join('\n')

  robot.respond /search (.+)/i, (msg) =>
    factoids = factoids.search msg.match[1]

    if factoids.length > 0
      msg.reply "Matched the following factoids: *#{factoids.join '*, *'}*"
    else
      msg.reply 'No factoids matched'

  robot.respond /drop (.+)/i, (msg) =>
    user = msg.envelope.user
    isAdmin = robot.auth?.hasRole(user, 'factoids-admin') or robot.auth?.hasRole(user, 'admin')
    if isAdmin or not robot.auth?
      factoid = msg.match[1]
      if factoids.drop factoid
        msg.reply "OK, #{factoid} has been dropped"
      else msg.reply "Not a factoid"
    else msg.reply "You don't have permission to do that."
