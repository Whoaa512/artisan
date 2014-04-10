fs = require 'fs'
Parse = require('parse').Parse
Parse.initialize "3KYb9b80UNTXltAM6bGuWRrxRlSu816sa07Cqkk1", "AZxCHrOxKH5LydCGBeTHY4GO4yFpj3GSPkUNGkqF"

# Session = Parse.
# query = new Parse.Query Event
# query.find().then (object)->
#   object.sort (a,b)->
#     a.get 'timeStamp' - b.get 'timeStamp'
#   results = []
#   _.each object, (model)->
#     results.push _.pick(model, 'attributes')
#   console.log JSON.stringify results