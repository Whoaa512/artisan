_ = require 'lodash'
async = require 'async'
Jeeves = require 'jeeves'
wd = require 'wd'

# takes   |> eventQueue
# returns |> new eventQueue with chained keypress events as a single `typedKeys` event
consolidateKeypresses = (eventQueue) ->
  newQueue = []
  chainStart = false
  typedKeys =
    eventType: 'typedKeys'
    _keys: []

  for ev,i in eventQueue
    prevEventType = eventQueue[i - 1].eventType ? null

    if ev.eventType is 'keypress'
      if not chainStart
        chainStart = true
        # copy relevant info on first keypress
        _.defaults typedKeys, ev
        try delete typedKeys.meta.pressedKey

      # update timestamp to be the last key pressed
      typedKeys.timestamp = ev.timestamp
      typedKeys._keys.push ev.pressedKey
    else
      if prevEventType is 'keypress'
        chainStart = false # close the chain
        newQueue.push typedKeys
      else
        newQueue.push ev

  newQueue


# takes   |> eventQueue
# returns |> new eventQueue with explicit waits between each action
#         @todo: optimize the waiting between
addExplicitWaits = (eventQueue) ->
  newQueue = []
  for ev,i in eventQueue
    newQueue.push ev
    timeDiff = eventQueue[i + 1].timestamp - ev.timestamp
    explicitWait =
      eventType: 'explicitWait' # could also be 'waitFor'
      targetElemCssPath: null # possibly used later to wait for element to show
      timestamp: ev.timestamp + 1 # timestamp the wait 1ms after prev event
      meta: null
      timeToWait: timeDiff if not _.isNan timeDiff else 0
    newQueue.push explicitWait

  newQueue


# takes   |> eventObj
# returns |> string equivalent of jeeves method
_findJeevesMethod = (eventObj) ->
  switch eventObj.eventType
    when 'explicitWait' then 'explicitWait'
    when 'click'        then 'clickElementByCss'
    when 'typedKeys'    then 'typeKeys'
    when 'keypress'
      console.error 'keypress event found! Should have been consolidated already.'
      null
    else null


# takes   |> eventObj
# returns |> array of args based on eventObj.eventType
_findMethodArgs = (eventObj) ->
  args = []
  switch eventObj.eventType
    when 'explicitWait'
      args.push eventObj.timeToWait
    when 'click'
      args.push eventObj.targetElemCssPath
    when 'typedKeys'
      args.push eventObj._keys.join ''
  args



# takes   |> eventObj
# returns |> actionObj - equivalent jeeves method + args to complete the action
actionBuilder = (eventObj) ->
  # actionObj =
  method: _findJeevesMethod eventObj
  args: _findMethodArgs eventObj


# takes   |> eventQueue
# returns |> actionList - list of actions(runnable methods)
parseQueue = _.compose addExplicitWaits, consolidateKeypresses

buildList = (eventQueue) ->
  consolidateQueue = parseQueue eventQueue
    actionList = _.map consolidateQueue, actionBuilder


# takes   |> actionList
# returns |> execution of list using methods from jeeves
queueRunner = (actionList, done) ->
  driver = new wd.promiseChainRemote()
  jeeves = new Jeeves driver

  tasks = _.map actionList, (action) ->
    (next) ->
      jeeves[action.method].apply null, action.args.concat next

  tasks.unshift (next) ->
    driver.init browserName: process.env.WDBROWSER ? 'phantomjs', next

  async.series tasks, done
