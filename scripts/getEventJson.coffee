fs = require 'fs'
_ = require 'lodash'
Parse = require('parse').Parse

Parse.initialize "3KYb9b80UNTXltAM6bGuWRrxRlSu816sa07Cqkk1", "AZxCHrOxKH5LydCGBeTHY4GO4yFpj3GSPkUNGkqF"

Event = Parse.Object.extend 'Event'
query = new Parse.Query Event
query.ascending('timeStamp').find().then (events)->
  eventData = []
  _.each events, (event)->
    eventData.push event.attributes

  fs.writeFile 'event-data.json', JSON.stringify(eventData), (err)->
    if err then throw err





# sessionQuery
# query.ascending('createdAt').limit(10).find().then (sessions)->
#   _.each sessions, (session)->
#     console.log session.get('eventQueue')
# withResponse = (sessionId)->
#   return (results)->
#     eventQueues[sessionId] = results