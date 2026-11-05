local AD = AccurateDashboard
local C = AD.Config

function AD.areaXY(v, areaId)
  local ok, center = pcall(function()
    return v:getAreaCenter(areaId)
  end)

  if not ok or not center then
    return nil
  end

  return center:getX(), center:getY()
end

function AD.averageOf(v, ids)
  local sx, sy, n = 0, 0, 0

  for _, id in ipairs(ids) do
    local x, y = AD.areaXY(v, id)

    if x then
      sx, sy, n = sx + x, sy + y, n + 1
    end
  end

  if n == 0 then
    return nil
  end

  return sx / n, sy / n
end

function AD.computeTankLocation(v)
  local tx, ty = AD.areaXY(v, "GasTank")
  if not tx then
    return nil
  end

  local lx, ly = AD.averageOf(v, { "TireFrontLeft", "TireRearLeft" })
  local rx, ry = AD.averageOf(v, { "TireFrontRight", "TireRearRight" })

  if not lx or not rx then
    return nil
  end

  local axisX, axisY = lx - rx, ly - ry
  local len = math.sqrt(axisX * axisX + axisY * axisY)

  if len < 0.01 then
    return nil
  end

  local midX, midY = (lx + rx) / 2, (ly + ry) / 2
  local dx, dy = tx - midX, ty - midY
  local offset = (dx * axisX + dy * axisY) / len

  local side
  if math.abs(offset) < C.fuel.centerTolerance then
    side = "Center"
  else
    side = offset > 0 and "Left" or "Right"
  end

  local pos = nil

  local fx, fy = AD.averageOf(v, { "TireFrontLeft", "TireFrontRight" })
  local bx, by = AD.averageOf(v, { "TireRearLeft", "TireRearRight" })

  if fx and bx then
    local fwdX, fwdY = fx - bx, fy - by
    local fwdLen = math.sqrt(fwdX * fwdX + fwdY * fwdY)

    if fwdLen > 0.01 then
      local along = (dx * fwdX + dy * fwdY) / fwdLen

      if along > C.fuel.lengthwiseThreshold then
        pos = "front"
      elseif along < -C.fuel.lengthwiseThreshold then
        pos = "rear"
      else
        pos = "middle"
      end
    end
  end

  return side, pos
end

function AD.getTankLocation(v)
  local script = v:getScript()
  local key = script and script:getFullName()

  local side, pos
  local cached = key and AD.Cache.tankLocation[key]

  if cached == nil then
    side, pos = AD.computeTankLocation(v)

    if key then
      AD.Cache.tankLocation[key] = side and { side = side, pos = pos } or false
    end
  elseif cached then
    side, pos = cached.side, cached.pos
  end

  local override = key and C.fuel.sideOverrides[key]
  if override then
    if type(override) == "table" then
      return override.side or side, override.pos or pos
    end

    return override, pos
  end

  return side, pos
end

function AD.getFuelInfo(v)
  local pct

  local okp, p = pcall(function()
    return v:getRemainingFuelPercentage()
  end)

  if okp and type(p) == "number" then
    pct = p
  end

  local amount, capacity

  local okPart, part = pcall(function()
    return v:getPartById("GasTank")
  end)

  if okPart and part then
    local oka, a = pcall(function()
      return part:getContainerContentAmount()
    end)

    local okc, c = pcall(function()
      return part:getContainerCapacity()
    end)

    if oka and okc and type(a) == "number" and type(c) == "number" and c > 0 then
      amount, capacity = a, c
      pct = pct or (a / c * 100)
    end
  end

  return pct, amount, capacity
end

function AD.fuelAmountLine(v)
  local pct, amount, capacity = AD.getFuelInfo(v)

  if not pct then
    return nil
  end

  local label = AD.localized("Tooltip_AccurateDash_Fuel", "Fuel")
  local pctInt = math.floor(pct + 0.5)

  if amount then
    return string.format(
      "%s: %.1f / %.0f%s (%d%%)",
      label,
      amount,
      capacity,
      C.fuel.unit,
      pctInt
    )
  end

  return string.format("%s: %d%%", label, pctInt)
end

function AD.fuelTooltipLines(v)
  local lines = {}

  local side, pos = AD.getTankLocation(v)

  if side then
    local text = AD.localized("Tooltip_RetroDash_TankLocation", "Tank location")
        .. ": "
        .. AD.localized("Tooltip_RetroDash_" .. side, side)

    if pos then
      text = text .. " (" .. AD.localized("Tooltip_AccurateDash_" .. pos, pos) .. ")"
    end

    lines[#lines + 1] = text
  end

  if C.fuel.showAmount then
    local fuel = AD.fuelAmountLine(v)
    if fuel then
      lines[#lines + 1] = fuel
    end
  end

  return lines
end
