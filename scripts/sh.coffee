# Description:
#   コマンド実行
#
# Commands:
#   hubot sh <command>
#
# URLS:
#   /hubot/sh
#
# Notes:
#   These commands are grabbed from comment blocks at the top of each file.
#
# Author:
#   Takegami

module.exports = (robot) ->

  #
  # コマンド実行
  #
  robot.respond /sh (.*)$/i, (msg) ->
    @exec = require('child_process').exec
    command = "#{msg.match[1]}"
    msg.send command

    @exec command, (error, stdout, stderr) ->
      if error?
        msg.send error
      else
        msg.send stdout
