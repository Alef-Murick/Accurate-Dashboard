local AD = AccurateDashboard

AD.Config = {
  summerCarId = "MaskaradsSummerCar",

  temp = {
    min = 20,
    max = 180,
    cold2 = 45,
    cold1 = 70,
    hot1 = 130,
    hot2 = 150,
  },

  alert = {
    enabled = true,
    blinks = 5,
    phaseMs = { 350, 250 },
    repeatSeconds = 0,
    hysteresis = 5,
    arrows = true,
    arrowsOpposite = false,
    sound = true,
  },

  fuel = {
    centerTolerance = 0.15,
    lengthwiseThreshold = 0.5,
    showAmount = true,
    unit = "L",
    sideOverrides = {
      -- ["Base.nome_do_carro"] = "Right",
      -- ["Base.outro_carro"] = { side = "Left", pos = "rear" },
    },
  },

  hover = {
    language = auto,
    pad = 10,
    mazdaIconPad = 8,
    mazdaLettersGap = 6,
  },

  styles = {
    bar = {
      "renderTrueno",
      "renderMazda",
      "renderSubaru",
      "renderNissan",
    },
    panel = {
      "renderTrueno",
      "renderMazda",
      "renderSubaru",
      "renderNissan",
      "renderMaestro",
      "renderMonaco",
    },
  },
}

AD.Config.temp.coldBelow = AD.Config.temp.cold1
AD.Config.temp.hotFrom = AD.Config.temp.hot1
AD.Config.alert.overheatFrom = AD.Config.temp.hot1
AD.Config.alert.criticalFrom = AD.Config.temp.hot2
