
Event = Parse.Object.extend 'Event'
query = new Parse.Query Event
query.find().then (object)->
  object.sort (a,b)->
    a.get 'timeStamp' - b.get 'timeStamp'
  results = []
  _.each object, (model)->
    results.push _.pick(model, 'attributes')
  console.log JSON.stringify results