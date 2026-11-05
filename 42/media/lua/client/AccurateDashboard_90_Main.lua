local AD = AccurateDashboard
local C = AD.Config

function AD.install()
  if not RetroDashboard then
    return
  end

  if RetroDashboard.accurateDashHooked
      or RetroDashboard.engineTempHooked
      or RetroDashboard.fuelSideHooked then
    return
  end

  RetroDashboard.accurateDashHooked = true
  RetroDashboard.engineTempHooked = true
  RetroDashboard.fuelSideHooked = true

  if AD.hasSummerCar() then
    AD.installNeedleHook()

    for _, name in ipairs(C.styles.panel) do
      AD.wrapPanelBlink(name)
    end

    for _, name in ipairs(C.styles.bar) do
      AD.wrapBarStyle(name)
    end

    AD.installMazdaClimate()
    AD.installTempHover()
  end

  AD.installTooltipRender()
end

Events.OnGameStart.Add(function()
  AD.install()
end)
