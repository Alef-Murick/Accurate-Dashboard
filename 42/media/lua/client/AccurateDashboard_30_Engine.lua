local AD = AccurateDashboard
local C = AD.Config

function AD.getEngineTemp(vehicle)
  local data = vehicle and vehicle:getModData()
  local sim = data and data.MSC and data.MSC.simulation
  return sim and tonumber(sim.engineTemperatureC)
end

function AD.formatTemp(celsius, dash)
  local useF = false

  if dash and dash.rd_useKmh ~= nil then
    useF = not dash.rd_useKmh
  else
    local core = getCore()
    useF = core.getOptionTemperatureDisplayCelsius ~= nil
        and not core:getOptionTemperatureDisplayCelsius()
  end

  if useF then
    return string.format("%d F", math.floor(celsius * 9 / 5 + 32 + 0.5))
  end

  return string.format("%d C", math.floor(celsius + 0.5))
end

function AD.alertLevelFor(temp, oldLevel)
  local A = C.alert

  if temp >= A.criticalFrom then
    return 2
  end

  if oldLevel == 2 and temp >= A.criticalFrom - A.hysteresis then
    return 2
  end

  if temp >= A.overheatFrom then
    return 1
  end

  if oldLevel >= 1 and temp >= A.overheatFrom - A.hysteresis then
    return 1
  end

  return 0
end

function AD.alertState(dash, temp)
  local A = C.alert

  if not A.enabled then
    return 0, false, false
  end

  local now = AD.nowMs()
  if not now then
    return 0, false, false
  end

  local st = dash.accDash
  if not st or st.vehicle ~= dash.vehicle then
    local quiet = A.blinks * 2 * math.max(A.phaseMs[1], A.phaseMs[2]) + 1
    st = {
      vehicle = dash.vehicle,
      level = AD.alertLevelFor(temp, 0),
      start = now - quiet,
    }
    dash.accDash = st
  end

  local level = AD.alertLevelFor(temp, st.level)

  if level > st.level then
    st.start = now
  elseif level > 0 and A.repeatSeconds > 0 and now - st.start >= A.repeatSeconds * 1000 then
    st.start = now
  end

  st.level = level

  if level == 0 then
    return 0, false, false
  end

  local phase = A.phaseMs[level]
  local elapsed = now - st.start

  if elapsed >= A.blinks * 2 * phase then
    return level, false, false
  end

  return level, true, math.floor(elapsed / phase) % 2 == 0
end

function AD.playAlertSound()
  if not C.alert.sound then
    return
  end

  if not RetroDashboard or not RetroDashboard.getCoords then
    return
  end

  local coords = RetroDashboard.getCoords()
  local sound = coords and coords.SND_BACKLIGHT

  if sound and getSoundManager then
    getSoundManager():playUISound(sound)
  end
end

function AD.drawEngineTempBar(dash, coords, S, temp, tb)
  local frac = AD.tempToFrac(temp, tb.count, tb.redCount)
  local lit = AD.isCarOn(dash.vehicle) and math.max(1, math.ceil(frac * tb.count)) or 0
  local color = coords.COLOR or { r = 1, g = 1, b = 1 }

  for i = 1, tb.count do
    local x = tb.x * S
    local y = (tb.y - (i - 1) * (tb.segH + tb.gap)) * S

    local isRed = i > tb.count - tb.redCount
    local r, g, b

    if isRed then
      r, g, b = 1.0, 0.12, 0.06
    elseif i <= 2 then
      r, g, b = 0.18, 0.64, 0.89
    else
      r, g, b = color.r, color.g, color.b
    end

    local on = i <= lit
    local m = on and 1 or 0.22

    dash:drawRect(
      x,
      y,
      tb.segW * S,
      tb.segH * S,
      on and 0.95 or 0.22,
      r * m,
      g * m,
      b * m
    )
  end
end

function AD.drawClimateTex(dash, state, x, y, w, h, W, H)
  if not state then
    return
  end

  local tex = RetroDashboard.tex("em_air_" .. state)
  if not tex then
    return
  end

  dash:setStencilRect(x, y, w, h)
  dash:drawTextureScaled(tex, 0, 0, W, H, 1, 1, 1, 1)
  dash:clearStencilRect()
end

function AD.drawMazdaClimate(dash, heaterStateFn)
  local temp = AD.getEngineTemp(dash.vehicle)
  if not temp then
    return
  end

  local S = RetroDashboard.scale
  local coords = RetroDashboard.getCoords()
  local hb = coords.buttons and coords.buttons.heater

  if not hb then
    return
  end

  local W, H = coords.CANVAS_W * S, coords.CANVAS_H * S

  local heaterState
  if heaterStateFn then
    heaterState = heaterStateFn(dash)
  end

  AD.drawClimateTex(
    dash,
    heaterState,
    (hb.x - C.hover.mazdaIconPad) * S,
    (hb.y - C.hover.mazdaIconPad) * S,
    (hb.w + C.hover.mazdaIconPad * 2) * S,
    (hb.h + C.hover.mazdaIconPad * 2) * S,
    W,
    H
  )

  local state = nil
  if AD.isCarOn(dash.vehicle) then
    if temp < C.temp.coldBelow then
      state = "cold"
    elseif temp >= C.temp.hotFrom then
      state = "hot"
    end
  end

  AD.drawClimateTex(
    dash,
    state,
    0,
    0,
    (hb.x - C.hover.mazdaLettersGap) * S,
    H,
    W,
    H
  )
end

function AD.getTempZone(coords)
  local pad = C.hover.pad

  local tb = coords.tempBar
  if tb and tb.count and tb.count > 0 and tb.x and tb.y and tb.segH and tb.segW and tb.gap then
    local top = tb.y - (tb.count - 1) * (tb.segH + tb.gap)
    local bottom = tb.y + tb.segH

    return tb.x - pad,
        top - pad,
        tb.segW + pad * 2,
        (bottom - top) + pad * 2
  end

  local tn = coords.tempNeedle
  if tn and tn.radius and tn.cx and tn.cy then
    return tn.cx - tn.radius,
        tn.cy - tn.radius,
        tn.radius * 2,
        tn.radius * 2
  end

  return nil
end

function AD.engineTempTooltipText(temp, dash)
  return AD.localized("Tooltip_AccurateDash_EngineTemp", "Engine temperature")
      .. ": "
      .. AD.formatTemp(temp, dash)
end
