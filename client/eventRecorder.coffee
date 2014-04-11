Event = Parse.Object.extend 'Event'

EventQueue = Parse.Collection.extend
  model: Event

Navigator = Parse.Object.extend 'Navigator'

Session = Parse.Object.extend 'Session',
  startRecording: (sessionName = 'general')->
    @eventQueue = new EventQueue()
    @navigator = new Navigator _.pick window.navigator, ['product', 'productSub', 'userAgent', 'vendor', 'language', 'appCodeName', 'appName', 'appVersion', 'cookieEnabled']
    myJax = $.ajax
    $.ajax = (params...) =>
      setCallBack params, @eventQueue
      @eventQueue.add new Event
        timeStamp: Date.now()
        sinceLastEvent: Date.now() - @eventQueue.at(@eventQueue.length - 1)?.get('timeStamp') or Date.now()
        type: 'jQueryAJAXOut'
        eventDataJSON: {params}
      myJax.apply $, params
    _.each @get('eventTypes'), (eventType) =>
      $(window).on eventType, (event) =>
        @eventQueue.add getEventData(event, @eventQueue.at(@eventQueue.length - 1)?.get('timeStamp') or Date.now())

  stopRecording: ->
    @save
      eventQueue: @eventQueue
      navigator: @navigator

  setCallBack = (params, eventQueue)=>
    objFound = _.reduce params, (
      (seenObj, param)=>
        if _.isObject(param)
          theirSuccessCallback = param.success
          theirFailureCallback = param.error
          param.success = ()=>
            eventQueue.add new Event
              timeStamp: Date.now()
              sinceLastEvent: Date.now() - eventQueue.at(eventQueue.length - 1)?.get('timeStamp') or Date.now()
              type: 'jQueryAJAXIn'
              eventDataJSON: {params, response:arguments}
            theirSuccessCallback? arguments
          param.error = ()=>
            eventQueue.add new Event
              timeStamp: Date.now()
              sinceLastEvent: Date.now() - eventQueue.at(eventQueue.length - 1)?.get('timeStamp') or Date.now()
              type: 'jQueryAJAXIn'
              eventDataJSON: {params, response:arguments}
            theirFailureCallback? arguments
    ), false
    unless objFound
      Array.prototype.push.call params,
        success: =>
          eventQueue.add new Event
            timeStamp: Date.now()
            sinceLastEvent: Date.now() - eventQueue.at(eventQueue.length - 1)?.get('timeStamp') or Date.now()
            type: 'jQueryAJAXIn'
            eventDataJSON: {params, response:arguments}
        error: =>
          eventQueue.add new Event
            timeStamp: Date.now()
            sinceLastEvent: Date.now() - eventQueue.at(eventQueue.length - 1)?.get('timeStamp') or Date.now()
            type: 'jQueryAJAXIn'
            eventDataJSON: {params, response:arguments}

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
    _.pick event, config[event.type]

session = new Session
  sessionName: 'booo'
  eventTypes: ['click', 'keypress']

session.startRecording()
window.stop = _.bind session.stopRecording, session