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
    robot.brain.data.sh = {} if !robot.brain.data.sh
    enabled = if robot.brain.data.sh["enabled"]? then robot.brain.data.sh["enabled"] else []

    @wexec = require('child_process').exec
    command = "#{msg.match[1]}"
    cmds    = command.split(" ")

    # whichコマンドでコマンドか確認
    tcmd = command.replace /;/g, " "
    tcmd = tcmd.replace /&&/g, " "
    tcmd = tcmd.replace /`/g, " "

    @wexec "which #{tcmd}", (error, stdout, stderr) ->
      wrets = stdout.split("\n")
      for wret in wrets

        # コマンドが登録されているか確認
        cmd = wret.split("/").pop()
        unless cmd.length == 0 or enabled.indexOf(cmd) >= 0
          msg.send "#{cmd}コマンドは許可がありません。"
          return

        @exec = require('child_process').exec
        @exec command, (error, stdout, stderr) ->
          if error?
            msg.send "#{command}\n#{error}"
          else
            msg.send "#{command}\n#{stdout}"

  #
  # コマンド追加
  #
  robot.respond /sh_add (.*)$/i, (msg) ->
    @exec = require('child_process').exec
    command = msg.match[1]
    cmds = msg.match[1].split(" ")

    @exec "which #{command}", (error, stdout, stderr) ->

      # コマンドの最大文字列長を取得
      maxlen = 0
      for cmd in cmds
        maxlen = Math.max(cmd.length, maxlen)

      # 結果文字列生成
      result = ""
      lines  = stdout.split("\n")

      # 設定値を取得
      robot.brain.data.sh = {} if !robot.brain.data.sh
      enabled = if robot.brain.data.sh["enabled"]? then robot.brain.data.sh["enabled"] else []

      for cmd, i in cmds
        if cmd.length == 0 or lines[i].length == 0 then continue

        # 出力を整形
        cmdname = "#{cmd + Array(maxlen).join ' '}".slice(0, maxlen)
        if lines[i].split('/').pop() == cmd
          if enabled.indexOf(cmd) == -1
            result += "#{cmdname} - [ OK ]\n"
            enabled.push(cmd)
          else
            result += "#{cmdname} - [ OK ] already setting.\n"
        else
          result += "#{cmdname} - [ NG ] not installed.\n"
          i--

      robot.brain.data.sh["enabled"] = enabled
      robot.brain.save()

      msg.send result

  #
  # コマンド削除
  #
  robot.respond /sh_remove (.*)$/i, (msg) ->
    result = "remove :\n"
    robot.brain.data.sh = {} if !robot.brain.data.sh
    enabled = if robot.brain.data.sh["enabled"]? then robot.brain.data.sh["enabled"] else []

    cmds = msg.match[1].split(" ")
    for cmd in cmds
      index = enabled.indexOf(cmd)
      if index >= 0
        enabled.splice(index, 1)
        result += "  #{cmd}\n"

    msg.send result

  #
  # コマンドリスト
  #
  robot.respond /sh_list$/i, (msg) ->
    result = ""
    robot.brain.data.sh = {} if !robot.brain.data.sh
    enabled = if robot.brain.data.sh["enabled"]? then robot.brain.data.sh["enabled"] else []
    for cmd in enabled
      result += "#{cmd}\n"

    if result.length == 0
      result = "ぷーん"
    msg.send result
