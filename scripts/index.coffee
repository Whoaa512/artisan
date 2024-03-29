_ = require 'lodash'
async = require 'async'
Jeeves = require 'jeeves'
wd = require 'wd'
{readJsonSync} = require 'fs-extra'
{fetchEventsJson} = require './getEventJson.coffee'
LOGS_ON = no
WAIT_TO_IGNORE = 450 # in ms

_log = ->
  if LOGS_ON
    console.log.apply this, arguments

# takes   |> eventQueue
# returns |> new eventQueue with unused events removed
removeUnusedEvents = (eventQueue) ->
  _log "removeUnusedEvents called, eventQueue.length: #{eventQueue.length}"
  newQueue = []

  for ev,i in eventQueue
    switch ev.type
      when 'click'    then newQueue.push ev
      when 'keypress' then newQueue.push ev
  _log "Unused events removed, new eventQueue.length: #{newQueue.length}"
  newQueue


# takes   |> eventQueue
# returns |> new eventQueue with chained keypress events as a single `typedKeys` event
consolidateKeypresses = (eventQueue) ->
  _log "consolidateKeypresses called, eventQueue.length: #{eventQueue.length}"
  newQueue = []
  chainStart = false
  typedKeys =
    type: 'typedKeys'
    _keys: []

  for ev,i in eventQueue
    prevEventType = eventQueue[i - 1]?.type ? null

    if ev.type is 'keypress'
      if not chainStart
        chainStart = true
        # copy relevant info on first keypress
        _.defaults typedKeys, ev

      # update endTimeStamp to match the last key pressed
      typedKeys.endTimeStamp = ev.timeStamp
      keyCode = ev.eventDataJSON?.keyCode
      _log '~~keyCode', keyCode
      _log '~~charFromCode', String.fromCharCode(keyCode)
      typedKeys._keys.push String.fromCharCode(keyCode)
    else
      if prevEventType is 'keypress'
        chainStart = false # close the chain
        _log 'typedKeys being pushed', typedKeys
        newQueue.push typedKeys
      else
        newQueue.push ev

  _log "Key presses consolidated, new eventQueue.length: #{newQueue.length}"
  newQueue


# takes   |> eventQueue
# returns |> new eventQueue with explicit waits between each action
#         @todo: optimize the waiting between
addExplicitWaits = (eventQueue) ->
  _log "addExplicitWaits called, eventQueue.length: #{eventQueue.length}"
  newQueue = []
  for ev,i in eventQueue
    newQueue.push ev
    timeDiff = ev.sinceLastEvent
    _log "!~~timeDiff: #{timeDiff}"
    explicitWait =
      type: 'explicitWait' # could also be 'waitFor'
      targetSelector: null # possibly used later to wait for element to show
      timeStamp: ev.timeStamp + 1 # timeStamp the wait 1ms after prev event
      meta: null
      timeToWait: if not _.isNaN timeDiff then timeDiff else 1
    if explicitWait.timeToWait >= WAIT_TO_IGNORE
      _log 'explicitWait being pushed', explicitWait
      newQueue.push explicitWait
    else
      _log "explicitWait was lower than #{WAIT_TO_IGNORE}ms, skipping"

  _log "Waits added, new eventQueue.length: #{newQueue.length}"
  newQueue


# takes   |> eventObj
# returns |> string equivalent of jeeves method
_findJeevesMethod = (eventObj) ->
  meth = switch eventObj.type
    when 'explicitWait' then 'explicitWait'
    when 'click'        then 'clickElementByCss'
    # when 'typedKeys'    then 'typeKeys'
    when 'keypress'
      # console.error 'keypress event found! Should have been consolidated already.'
      'typeKeys'
    else null
  _log "_findJeevesMethod called, method returned: #{meth}"
  meth


# takes   |> eventObj
# returns |> array of args based on eventObj.type
_findMethodArgs = (eventObj) ->
  args = []
  switch eventObj.type
    when 'explicitWait'
      args.push eventObj.timeToWait / 1000
    when 'click'
      args.push eventObj.targetSelector
    when 'typedKeys'
      args.push eventObj._keys.join ''
    when 'keypress'
      args.push String.fromCharCode(eventObj.eventDataJSON?.keyCode)
  _log "_findMethodArgs called, args returned: #{JSON.stringify args}"
  args


# takes   |> eventObj
# returns |> actionObj - equivalent jeeves method + args to complete the action
actionBuilder = (eventObj) ->
  # actionObj =
  method: _findJeevesMethod eventObj
  args: _findMethodArgs eventObj


# takes   |> eventQueue
# returns |> actionList - list of actions(runnable methods)
# parseQueue = _.compose addExplicitWaits, consolidateKeypresses, removeUnusedEvents
parseQueue = _.compose addExplicitWaits, removeUnusedEvents

buildList = (eventQueue) ->
  consolidateQueue = parseQueue eventQueue
  actionList = _.map consolidateQueue, actionBuilder


# takes   |> actionList
# returns |> execution of list using methods from jeeves
queueRunner = (actionList, startUrl, done) ->
  driver = new wd.promiseChainRemote()
  jeeves = new Jeeves driver

  tasks = _.map actionList, (action) ->
    (next) ->
      jeeves[action.method].apply jeeves, action.args.concat next

  setupTasks = [
      (next) ->
        driver.init browserName: process.env.WDBROWSER ? 'chrome', next
    ,
      (next) ->
        driver
          .get(startUrl)
          .nodeify next
    ]

  cleanUpTasks = [
      (next) ->
        driver.quit next
    ]

  async.series setupTasks.concat(tasks, cleanUpTasks), done


##########################
# cli Args
args = require 'nomnom'
  .options
    fecth:
      abbr: 'f'
      help: 'Flag to determine if JSON should be freshly fetched. [default]: true'
      flag: true
      default: false
    debug:
      abbr: 'd'
      help: 'Flag to turn on debug logging. [default]: false'
      flag: true
      default: false
  .parse()


if args.debug then LOGS_ON = yes

jsonData = actionList = null

async.series
  fetchJson: (next) ->
    if args.fecth
      fetchEventsJson next
    else next()
  readJson: (next) ->
    jsonData = readJsonSync 'event-data.json'
    next()
  buildList: (next) ->
    actionList = buildList jsonData
    console.log 'List built~'
    _log '~~action list:',actionList
    next()
  runQueue: (next) ->
    console.log 'Running actions~'
    startUrl = 'http://10.11.12.165:5050/login'
    queueRunner actionList, startUrl, next
, (error) ->
  if error then console.log 'Error!', error
  console.log 'Done running actions'
  process.exit 0
