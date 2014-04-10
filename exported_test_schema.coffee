userObj =
  session_id
  environment_info
  user_id

queueOfEvents = [
    eventType: Sting |> [click, keypress]
    targetElemCssPath: Sting |> [css, id, class]
    timeStamp: Time # interpret waiting period based on timeStamp
    meta: # Object
      pressedKey: String # only on keypress events
  ,
    # explicitWait =
    eventType: 'explicitWait' # could also be 'waitFor'
    targetElemCssPath: null # possibly used later to wait for element to show
    timeStamp: event.timeStamp + 1 # timeStamp the wait 1ms after prev event
    meta: null
    timeToWait: timeDiff
  ,
    eventType: Sting |> [click, keypress]
    targetElemCssPath: Sting |> [css, id, class]
    timeStamp: Time # interpret waiting period based on timeStamp
    meta: Object
  ]


exports = {userObj, queueOfEvents}