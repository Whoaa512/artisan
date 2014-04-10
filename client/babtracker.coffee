Session = Parse.Object.extend 'Session'
Navigator = Parse.Object.extend 'Navigator'
Event = Parse.Object.extend 'Event'
EventQueue = Parse.Collection.extend
  model: Event

watchEvents = ['keypress', 'click']

eventQueue = null
session = null
navigator = null
window.foo = eventQueue
startRecording = ->
  session = new Session()
  navigator = new Navigator _.pick window.navigator, ['product', 'productSub', 'userAgent', 'vendor', 'language', 'appCodeName', 'appName', 'appVersion', 'cookieEnabled']
  eventQueue = new EventQueue()
  _.each watchEvents, (eventType)->
    $(window).on eventType, (event)->
      eventQueue.add getEventData(event, eventQueue.at(eventQueue.length - 1)?.get('timeStamp') or Date.now())

stopRecording = ->
  session?.save
    navigator: navigator
    eventQueue: eventQueue
  window.eventQueue = eventQueue

getEventData = (event, lastTimeStamp)->
  currentTime = Date.now()
  new Event
    timeStamp: currentTime
    sinceLastEvent: currentTime - (lastTimeStamp or 0)
    type: event.type
    targetSelector: getCSSSelector event
    eventDataJSON: getTypeSpecificData event

getCSSSelector = (event)->
  queries = [
    $(event.target).parent()[0].localName + if $(event.target).parent()[0].className then '.' + $(event.target).parent()[0].className.replace(/\s/, '.') else ''
    event.target.localName + if event.target.className then '.' + event.target.className.replace(/\s/, '.') else ''
  ]
  queries.join ' > '

getTypeSpecificData = (event)->
  config =
    keypress: ['keyCode']
  JSON.stringify _.pick(event, config[event.type])
