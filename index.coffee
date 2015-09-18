# Description:
#   Stores the brain in SQL Server
#
# Dependencies:
#   tedious
#
# Configuration:
#   HUBOT_MSSQL_CONNECTION
#
# Commands:
#   None
#
# Notes:
#   Run the following SQL to setup the table for storage:
#
#   create table hubot_brain (
#     id int identity primary key,
#     storage nvarchar(max)
#   )
#
#   insert into hubot_brain
#   values(null)
#
#   Thanks to danthompson and the pg-brain script for inspiration: https://github.com/github/hubot-scripts/blob/master/src/scripts/pg-brain.coffee
#
# Author:
#   robu

Tedious = require 'tedious'
Connection = Tedious.Connection
Request = Tedious.Request

# sets up hooks to persist the brain into postgres.
module.exports = (robot) ->

  mssqlConnection = process.env.HUBOT_MSSQL_CONNECTION

  if !mssqlConnection?
    throw new Error('mssql-brain requires a HUBOT_MSSQL_CONNECTION to be set.')

  connParts = mssqlConnection.split("|")

  if connParts.length < 4
    throw new Error("HUBOT_MSSQL_CONNECTION must be in the following format: server|db_name|username|password")

  connConfig =
    server: connParts[0]
    userName: connParts[2]
    password: connParts[3]
    options:
      database: connParts[1]
      useColumnNames: true

  # use instance name if provided
  if connParts.length = 5
    connConfig.options.instanceName = connParts[4]

  connection = new Connection(connConfig)
  connection.on "connect", (err) ->
    # initial load of the brain
    if err
      throw new Error(err)
    else
      robot.logger.debug "mssql-brain connected to #{connConfig.server}/#{connConfig.options.database}"
      request = new Request("SELECT TOP 1 storage FROM hubot_brain", (err, rowcount) ->
        if err
          robot.logger.error "error fetching brain data: " + err
      )

      request.on "row", (columns) ->
        if columns["storage"]?
          robot.logger.debug "mssql-brain loaded"
          robot.brain.mergeData JSON.parse(columns["storage"].value)

      connection.execSql(request)

  connection.on "error", (err) ->
    robot.logger.error err

  robot.brain.on 'save', (data) ->
    request = new Request("UPDATE hubot_brain SET storage = @data", (err, rowcount) ->
      if err
        robot.logger.error "error saving brain data: " + err
    )
    request.addParameter("data", Tedious.TYPES.NVarChar, JSON.stringify(data))
    connection.execSql(request)

    robot.logger.debug "mssql-brain saved"

  robot.brain.on 'close', ->
    connection.close()
