function onObjectDrop(colorName, obj)
  scriptingZoneObjects1 = getObjectFromGUID("72ad23").getObjects()
  for i,v in ipairs(scriptingZoneObjects1) do
      if v == obj then
          if obj.type == "Tile" then

              obj.destruct()
          elseif obj.type == "Dice" then
              obj.destruct()
          end
          break
      end
  end

  scriptingZoneObjects2 = getObjectFromGUID("bc81b3").getObjects()
  for i,v in ipairs(scriptingZoneObjects2) do
      if v == obj then
          if obj.type == "Tile" then

              obj.destruct()
          elseif obj.type == "Dice" then
              obj.destruct()
          end
          break
      end
  end
end

function onObjectSpawn(obj)
  if obj.type == 'Card' then
      obj.addTag('Card')
  end
end