local AD = AccurateDashboard

function AD.drawSimpleTooltip(dash, content)
  local lines = type(content) == "table" and content or { content }
  local font = UIFont.Small
  local fontH = getTextManager():getFontHeight(font)
  local pad = 6
  local maxW = 0

  for _, line in ipairs(lines) do
    local w = getTextManager():MeasureStringX(font, line)
    if w > maxW then
      maxW = w
    end
  end

  local boxW = maxW + pad * 2
  local boxH = #lines * fontH + pad * 2

  local mx = dash:getMouseX() + 12
  local my = dash:getMouseY() + 12

  if mx + boxW > dash:getWidth() then
    mx = dash:getMouseX() - boxW - 4
  end

  if my + boxH > dash:getHeight() then
    my = dash:getMouseY() - boxH - 4
  end

  dash:drawRect(mx, my, boxW, boxH, 0.85, 0.05, 0.05, 0.05)
  dash:drawRectBorder(mx, my, boxW, boxH, 1.0, 0.4, 0.4, 0.4)

  for i, line in ipairs(lines) do
    dash:drawText(
      line,
      mx + pad,
      my + pad + (i - 1) * fontH,
      1.0, 1.0, 1.0, 1.0,
      font
    )
  end
end

function AD.installTooltipRender()
  local T = RetroDashboard.Tooltip
  if not T or not T.render then
    return
  end

  local originalRender = T.render

  T.render = function(dash)
    local btn = dash.hoverBtn

    if btn == "engineTemp" then
      local temp = AD.getEngineTemp(dash.vehicle)
      if temp then
        AD.drawSimpleTooltip(dash, AD.engineTempTooltipText(temp, dash))
      end
      return
    end

    if btn == "fuelCap" and dash.vehicle then
      local lines = AD.fuelTooltipLines(dash.vehicle)
      if #lines > 0 then
        AD.drawSimpleTooltip(dash, lines)
        return
      end
    end

    return originalRender(dash)
  end
end
