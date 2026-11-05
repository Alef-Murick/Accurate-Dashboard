local AD = AccurateDashboard
local C = AD.Config

function AD.installNeedleHook()
  if type(RetroDashboard.drawNeedleGauge) ~= "function" then
    return
  end

  local originalDraw = RetroDashboard.drawNeedleGauge

  RetroDashboard.drawNeedleGauge = function(dash, gauge, value, S, on, tex, alpha)
    local coords = RetroDashboard.getCoords and RetroDashboard.getCoords()

    if coords and gauge == coords.tempNeedle and gauge.minVal and gauge.maxVal then
      local temp = AD.getEngineTemp(dash.vehicle)

      if temp then
        local frac = AD.tempToFrac(temp)
        value = gauge.minVal + frac * (gauge.maxVal - gauge.minVal)
        on = AD.isCarOn(dash.vehicle)
      end
    end

    return originalDraw(dash, gauge, value, S, on, tex, alpha)
  end
end

function AD.wrapPanelBlink(fnName)
  local original = RetroDashboard[fnName]
  if type(original) ~= "function" then
    return
  end

  RetroDashboard[fnName] = function(dash)
    local flashing, inverted = false, false

    if dash.vehicle then
      local temp = AD.getEngineTemp(dash.vehicle)

      if temp and AD.isDriving(dash) then
        local _, f, offPhase = AD.alertState(dash, temp)
        flashing = f
        inverted = f and offPhase
      end
    end

    local st = dash.accDash
    if st then
      if flashing then
        if st.lastInverted ~= inverted then
          st.lastInverted = inverted
          if inverted then
            AD.playAlertSound()
          end
        end
      else
        st.lastInverted = nil
      end
    end

    if not flashing then
      return original(dash)
    end

    local savedFade, savedMul = dash.rd_nightFade, dash.rd_flickerMul
    local savedLeft, savedRight = dash.rd_showLeft, dash.rd_showRight

    local base = savedFade
    if base == nil then
      if dash.rd_night ~= nil then
        base = dash.rd_night and 1 or 0
      elseif RetroDashboard.isNight then
        base = RetroDashboard.isNight() and 1 or 0
      else
        base = 0
      end
    end

    local night = base >= 0.5

    if inverted then
      dash.rd_nightFade = night and 0 or 1
      dash.rd_flickerMul = 1
    end

    if C.alert.arrows then
      local panelBright = (night and not inverted) or ((not night) and inverted)
      local arrowsOn = C.alert.arrowsOpposite and (not panelBright) or panelBright
      dash.rd_showLeft, dash.rd_showRight = arrowsOn, arrowsOn
    end

    local ok, err = pcall(original, dash)

    dash.rd_nightFade, dash.rd_flickerMul = savedFade, savedMul
    dash.rd_showLeft, dash.rd_showRight = savedLeft, savedRight

    if not ok then
      error(err, 0)
    end
  end
end

function AD.wrapBarStyle(fnName)
  local original = RetroDashboard[fnName]
  if type(original) ~= "function" then
    return
  end

  RetroDashboard[fnName] = function(dash)
    if not RetroDashboard.getCoords then
      return original(dash)
    end

    local coords = RetroDashboard.getCoords()
    local tb = coords.tempBar
    local temp = AD.getEngineTemp(dash.vehicle)

    if not temp or not tb or not tb.count or tb.count == 0 then
      return original(dash)
    end

    local savedCount = tb.count
    tb.count = 0

    local ok, err = pcall(original, dash)
    tb.count = savedCount

    if not ok then
      error(err, 0)
    end

    AD.drawEngineTempBar(dash, coords, RetroDashboard.scale, temp, tb)
  end
end

function AD.installMazdaClimate()
  if type(RetroDashboard.climateState) ~= "function" then
    return
  end

  if type(RetroDashboard.renderMazda) ~= "function" then
    return
  end

  local originalClimate = RetroDashboard.climateState

  RetroDashboard.climateState = function(d)
    if RetroDashboard.style == "mazda" and d and AD.getEngineTemp(d.vehicle) then
      return nil
    end

    return originalClimate(d)
  end

  local innerRender = RetroDashboard.renderMazda

  RetroDashboard.renderMazda = function(dash)
    innerRender(dash)
    AD.drawMazdaClimate(dash, originalClimate)
  end
end

function AD.installTempHover()
  local DASH = ISVehicleDashboard

  if not DASH or type(DASH.onMouseMove) ~= "function" then
    return
  end

  local originalMove = DASH.onMouseMove

  DASH.onMouseMove = function(self, dx, dy)
    originalMove(self, dx, dy)

    if self.hoverBtn or not self.vehicle then
      return
    end

    if not AD.getEngineTemp(self.vehicle) then
      return
    end

    if not RetroDashboard.getCoords then
      return
    end

    local x, y, w, h = AD.getTempZone(RetroDashboard.getCoords())
    if not x then
      return
    end

    local S = RetroDashboard.scale
    local mx, my = self:getMouseX(), self:getMouseY()

    if mx >= x * S and mx <= (x + w) * S and my >= y * S and my <= (y + h) * S then
      self.hoverBtn = "engineTemp"
    end
  end

  local originalOutside = DASH.onMouseMoveOutside

  DASH.onMouseMoveOutside = function(self, dx, dy)
    if self.hoverBtn == "engineTemp" then
      self.hoverBtn = nil
    end

    if originalOutside then
      return originalOutside(self, dx, dy)
    end
  end
end
