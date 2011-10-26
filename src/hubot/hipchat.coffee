Robot        = require "robot"
HTTPS        = require "https"
EventEmitter = require("events").EventEmitter
Wobot        = require("wobot").Bot

class HipChat extends Robot
  send: (user, strings...) ->
    console.log "Sending"
    strings.forEach (str) =>
      @bot.message user.room || user.id, str

  reply: (user, strings...) ->
    console.log "Replying"
    strings.forEach (str) =>
      @send user, "#{user.name}: #{str}"

  run: ->
    self = @
    @options =
      token:    process.env.HUBOT_HIPCHAT_TOKEN
      jid:      process.env.HUBOT_HIPCHAT_JID
      name:     process.env.HUBOT_HIPCHAT_NAME || "Hubot, I"
      password: process.env.HUBOT_HIPCHAT_PASSWORD

    console.log "Options:", @options
    bot = new Wobot(jid: @options.jid, name: @options.name, password: @options.password)
    console.log "Bot:", bot

    bot.onConnect =>
      console.log "Connected to HipChat"
      @get "/v1/rooms/list", (err, response)->
        response.rooms.forEach (room)->
          bot.join room.xmpp_jid
    bot.onError (message, stanza)->
      console.log "Received error from HipChat:", message, stanza
    bot.onMessage /^@hubot\s/i, (channel, from, message)->
      author = self.userForId(from)
      author.room = channel
      self.receive new Robot.Message(author, message.match(/@hubot (.*)/)[1])
    bot.onPrivateMessage (from, message)=>
      author = self.userForId(from)
      self.receive new Robot.Message(author, message)
    bot.connect()

    @bot = bot


  # Convenience HTTP Methods for posting on behalf of the token"d user
  get: (path, callback) ->
    @request "GET", path, null, callback

  post: (path, body, callback) ->
    @request "POST", path, body, callback

  request: (method, path, body, callback) ->
    console.log method, path, body
    headers = { "Host": "api.hipchat.com" }

    options =
      "agent"  : false
      "host"   : "api.hipchat.com"
      "port"   : 443
      "path"   : path
      "method" : method
      "headers": headers

    if method == "POST"
      body.auth_token = @options.token
      body = JSON.stringify(body)
      headers["Content-Type"] = "application/json"

      body = new Buffer(body)
      options.headers["Content-Length"] = body.length
    else
      options.path += "?auth_token=#{@options.token}"

    request = HTTPS.request options, (response) ->
      data = ""
      response.on "data", (chunk) ->
        data += chunk
      response.on "end", ->
        if response.statusCode >= 400
          console.log "hipchat error: #{response.statusCode}"

        try
          callback null, JSON.parse(data)
        catch err
          callback null, data || { }
      response.on "error", (err) ->
        callback err, { }

    if method == "POST"
      request.end(body, 'binary')
    else
      request.end()

    request.on "error", (err) ->
      console.log err
      console.log err.stack
      callback err

exports.HipChat = HipChat
