local AD = AccurateDashboard
local C = AD.Config

function AD.localized(key, fallback)
  local value = AD.L10N.T(key)
  if value ~= nil then return value end
  return fallback
end

function AD.nowMs()
  if getTimestampMs then
    return getTimestampMs()
  end
  return nil
end

function AD.hasSummerCar()
  local ok, res = pcall(function()
    return getActivatedMods():contains(C.summerCarId)
  end)

  if ok then
    return res == true
  end

  return true
end

function AD.isCarOn(v)
  return v and (
    v:isEngineRunning()
    or v:isKeysInIgnition()
    or v:isHotwired()
    or v:isStarting()
  )
end

function AD.isDriving(dash)
  local v = dash.vehicle
  if not v or not v:isEngineRunning() then
    return false
  end

  local ok, driver = pcall(function()
    return v:getDriver()
  end)

  if ok and driver and dash.character and driver ~= dash.character then
    return false
  end

  return true
end

function AD.tempToFrac(temp, count, redCount)
  count = count or 7
  redCount = redCount or 2

  local T = C.temp
  local pts = {
    { T.min,   0 },
    { T.cold2, 1 / count },
    { T.cold1, 2 / count },
    { T.hot1,  (count - redCount) / count },
    { T.hot2,  (count - 1) / count },
    { T.max,   1 },
  }

  if temp <= pts[1][1] then
    return 0
  end

  for i = 2, #pts do
    local a, b = pts[i - 1], pts[i]

    if temp <= b[1] then
      local span = b[1] - a[1]
      if span <= 0 then
        return b[2]
      end

      return a[2] + (temp - a[1]) / span * (b[2] - a[2])
    end
  end

  return 1
end
