--- Loads saved data.
-- TTS API Called when an object is loaded or spawned.
-- Sets rotation values.
-- @tparam tab saved_data JSON encoded table
function onLoad(saved_data)
  self.setRotationValues({
    {
      value = "Red",
      rotation = {0, 0, 0}
    },
    {
        value = "Blue",
        rotation = {0, 0, 180}
    },
  })
end
double-sided 
--- Called when the script-owner Object is randomized.
-- @tparam  string color Player Color of the player who triggered the function.
function onRandomize(color)

  startLuaCoroutine(self, 'whileDrop')
  printToAll(color .. " tossed a coin!", color)
end

--- Coroutine function running until coin is resting.
function whileDrop()
  while not self.resting do
   coroutine.yield(0) -- Always yield 0 to resume
  end

  printResult()
  coroutine.yield(1) -- Yield anything other than 0 to break out
end

--- Broadcasts result of a toss.
function printResult()
  local value = self.getValue()
  local color = Color.red

  if value == 1 then
    side = 'RED starts!'
  else
    side = 'BLUE starts!'
    color = Color.blue
  end
  broadcastToAll(side, color)
end