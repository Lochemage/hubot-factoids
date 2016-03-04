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
    factoid = factoids.get msg.match[1]
    if factoid and not factoid.forgotten
      factoid.popularity++
      msg.reply msg.match[1] + " is " + factoid.value

  robot.hear /^~(.+)/i, (msg) ->
    # tell <user> about <factoid>
    if match = /^~tell (.+) about (.+)/i.exec msg.match
      factoid = factoids.get msg.match[2]
      if factoid and not factoid.forgotten
        factoid.popularity++
        msg.send msg.match[1] + ": " + msg.match[2] + " is " + factoid.value
    # <factoid> is alias of <value>
    else if match = /^~(.+?) alias of (.+)/i.exec msg.match
      msg.reply "OK, #{match[1]} is now an alias of #{match[2]}" if factoids.set match[1], "@#{match[2]}", msg.message.user.name, false
    # <factoid> is also <value>
    else if match = /^~(.+?) is also (.+)/i.exec msg.match
      factoid = factoids.add match[1], match[2], msg.message.user.name
      msg.reply "OK, #{match[1]} is also #{match[2]}"
    # <factoid> is <value>
    else if match = /^~(.+?) is (.+)/i.exec msg.match
      factoid = factoids.set match[1], match[2], msg.message.user.name
      msg.reply "OK, #{match[1]} is #{factoid.value}"

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
