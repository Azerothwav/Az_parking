_Parkings = { 
   --[[{
    name = string - REQUIRED,
    blipName = string - OPTIONAL, 
    blipColor = number - OPTIONAL,
    zone = PolyZoneObject - REQUIRED, 
    fee  = number - REQUIRED,
    entrances  = {
      vector3(-279.25, -890.39, 30.08)
    },
    hideEntrance = boolean,
    maxcar = number,
    showEnter = boolean,
  }, ]]
  centralParkingArriba = {
    name = "Parking Central",
    fee    = 1200,
    maxcar = 25,
    entrances  = {
      vector3(224.52, -738.09, 33.0)
    },
    zone = PolyZone:Create({
      vector2(219.21, -753.44),
      vector2(264.1643371582, -768.44061279297),
      vector2(271.99243164062, -748.68383789062),
      vector2(226.43690490723, -733.07666015625)
    }, {
      minZ = 34.0,
      -- maxZ = 36.5,
    }),
  },
  central397 = {
    name = "Parking Central 397",
    fee    = 800,
    maxcar = 15,
    entrances  = {
      vector3(184.13, -724.73, 32.5),
      vector3(84.67, -693.39, 30.5),
    },
    zone = PolyZone:Create({
      vector2(186.8207244873, -688.10272216797),
      vector2(162.18891906738, -756.45104980469),
      vector2(85.613945007324, -728.63720703125),
      vector2(100.27899169922, -687.77575683594),
      vector2(148.82186889648, -674.33020019531)
    }, {
      minZ = 32.5,
      maxZ = 36.5,
      -- debugGrid=true
    }),
  },
  central209 = {
    name = "Parking Central 209",
    fee    = 1000,
    maxcar = 15,
    entrances  = {
      vector3(320.74, -700.35, 28.5),
    },
    zone = PolyZone:Create({
      vector2(322.45217895508, -693.83947753906),
      vector2(316.6965637207, -707.44232177734),
      vector2(284.78912353516, -696.00347900391),
      vector2(289.85623168945, -682.06231689453)
    }, {
      minZ = 28.5,
      -- maxZ = 36.5,
    }),
  },
  centralPisoPobre = {
    name = "Parking Z.E.R",
    maxcar = 8,
    fee = 500,
    entrances  = {
      vector3(307.37, -1071.23, 28.3),
    },
    zone = PolyZone:Create({
      vector2(297.74990844727, -1069.1755371094),
      vector2(309.69338989258, -1069.5327148438),
      vector2(310.73245239258, -1119.4951171875),
      vector2(298.04028320312, -1119.7993164062)
    }, {
      minZ = 28.5,
      -- maxZ = 36.5,
    }),
  },
  central213 = {
    name = "Parking 213",
    maxcar = 10,
    entrances  = {
      vector3(236.2, -1159.61, 28.2),
    },
    zone = PolyZone:Create({
      vector2(297.74990844727, -1069.1755371094),
      vector2(309.69338989258, -1069.5327148438),
      vector2(310.73245239258, -1119.4951171875),
      vector2(298.04028320312, -1119.7993164062)
    }, {
      minZ = 28.5,
      -- maxZ = 36.5,
    }),
  },
  ammunation200 = {
    name = "Parking Ammunation",
    entrances  = {
      vector3(54.62, -1058.32, 28.5),
    },
    maxcar = 10,
    zone = PolyZone:Create({
      vector2(-3.7880523204803, -1032.8937988281),
      vector2(-18.807891845703, -1073.7478027344),
      vector2(-0.10139285773039, -1080.2509765625),
      vector2(-8.3133583068848, -1105.0218505859),
      vector2(14.01505947113, -1113.78515625),
      vector2(25.972721099854, -1105.0301513672),
      vector2(51.863086700439, -1053.0716552734)
    }, {
      minZ = 37.0,
      -- debugGrid=true
    }),
  }, 
  ammunationAfuera = {
    name = "Parking Ammunation",
    entrances  = {
      vector3(38.57, -1101.62, 27.9),
    },
    maxcar = 5,
    zone = PolyZone:Create({
      vector2(51.788486480713, -1090.5505371094),
      vector2(38.689666748047, -1084.4910888672),
      vector2(20.36407661438, -1119.1564941406),
      vector2(31.362049102783, -1123.8967285156)
    }, {
      minZ = 27.9,
    }),
  },
  parking206 = {
    name = "Parking Central 206",
    entrances  = {
      vector3(100.03, -1067.86, 27.9),
    },
    maxcar = 10,
    zone = PolyZone:Create({
      vector2(110.2107925415, -1046.8802490234),
      vector2(96.416976928711, -1077.8547363281),
      vector2(113.95830535889, -1084.5230712891),
      vector2(149.40344238281, -1084.4375),
      vector2(147.11799621582, -1061.0041503906)
    }, {
      minZ = 28.0,
      maxZ = 32.0,
    }),
  },
  parking584 = {
    name = "Parking 584",
    fee    = 650,
    maxcar = 10,
    entrances  = {
      vector3(283.2, -354.98, 44.0),
    },
    zone = PolyZone:Create({
      vector2(295.3505859375, -354.30935668945),
      vector2(257.44253540039, -340.56881713867),
      vector2(267.17907714844, -313.36639404297),
      vector2(305.41983032227, -326.45709228516)
    }, {
      minZ = 28.5,
      -- maxZ = 36.5,
    }),
  },
  parkingEMS = {
    name = "Parking EMS",
    maxcar = 10,
    entrances  = {
      vector3(-418.87, -295.98, 34.0),
      vector3(-427.88, -366.45, 31.5),
    },
    zone = PolyZone:Create({
      vector2(-417.82141113281, -369.45944213867),
      vector2(-436.49029541016, -367.00939941406),
      vector2(-425.03530883789, -288.87603759766),
      vector2(-410.96200561523, -299.06228637695)
    }, {
      minZ = 31.0,
      -- maxZ = 36.5,
    }),
    jobs = { 'ambulance' }
  },
  parkingPublicoEMS = {
    name = "Parking EMS",
    fee    = 650,
    maxcar = 10,
    entrances  = {
      vector3(-365.90, -318.08, 31.0),
    },
    zone = PolyZone:Create({
      vector2(-339.15124511719, -338.39270019531),
      vector2(-329.2507019043, -314.31600952148),
      vector2(-403.99453735352, -260.50967407227),
      vector2(-420.80554199219, -279.41754150391)
    }, {
      minZ = 29.0,
      -- maxZ = 36.5,
    }),
  },
  parkingGratuitoEMS = {
    name = "Parking Gratuit EMS",
    maxcar = 10,
    entrances  = {
      vector3(-433.93, -440.62, 31.5),
    },
    zone = PolyZone:Create({
      vector2(-456.51409912109, -443.64981079102),
      vector2(-429.50225830078, -446.32495117188),
      vector2(-417.80718994141, -455.99887084961),
      vector2(-419.85702514648, -465.95944213867),
      vector2(-458.37075805664, -459.09002685547)
    }, {
      minZ = 31.0,
      -- maxZ = 36.5,
    }),
  },
  policeStation = {
    name = "Parking LSPD",
    maxcar = 10,
    entrances  = {
      vector3(-1058.56, -877.3, 5.0),
    },
    zone = PolyZone:Create({
      vector2(-1076.69, -876.02),
      vector2(-1051.69, -876.02),
      vector2(-1058.56, -876.02),
      vector2(-1058.56, -876.02),
      vector2(-1058.56, -876.02)
    }, {
      minZ = 24.0
    }),
    jobs = { 'police' }
  },
  taxiStation = {
    name = "Parking Taxi",
    maxcar = 5,
    entrances  = {
      vector3(914.64, -179.94, 72.8),
    },
    zone = PolyZone:Create({
      vector2(904.5625, -194.25276184082),
      vector2(926.24066162109, -160.93862915039),
      vector2(914.62322998047, -152.86856079102),
      vector2(890.79711914062, -185.71098327637)
    }, {
      minZ = 72.0
    }),
    jobs = { 'taxi' }
  },
  airlinesStation = {
    name = "Parking Aeroport",
    maxcar = 5,
    entrances  = {
      vector3(-997.39, -2908.48, 13.0),
    },
    zone = PolyZone:Create({
      vector2(-994.00, -2948.52),
      vector2(-974.33, -2914.63),
      vector2(-996.504, -2901.53),
      vector2(-1016.09, -2935.31),
    }, {
      minZ = 11.0
    }),
    jobs = { 'aeroportp' }
  },
  casinoStation = {
    name = "Parking Casino",
    fee    = 1500,
    entrances  = {
      vector3(924.85, -17.07, 77.00),
      vector3(879.96, -88.89, 78.00),
    },
    maxcar = 10,
    zone = PolyZone:Create({
      vector2(949.90808105469, -36.249973297119),
      vector2(934.86785888672, -64.720695495605),
      vector2(946.044921875, -81.659622192383),
      vector2(943.91174316406, -91.325477600098),
      vector2(926.20526123047, -107.20796966553),
      vector2(914.86871337891, -107.04007720947),
      vector2(851.87188720703, -67.271911621094),
      vector2(829.46838378906, -43.58727645874),
      vector2(872.38415527344, 13.005387306213)
    }, {
      minZ = 75.0
      -- debugGrid=true
    }),
    society = "society_casino"
  },
  parking382 = {
    name   = "Parking 382",
    fee    = 3000,
    entrances  = {
      vector3(-279.25, -890.39, 30.08)
    },
    maxcar = 15,
    zone = PolyZone:Create({
      vector2(-363.97412109375, -872.61242675781),
      vector2(-364.0071105957, -969.91284179688),
      vector2(-296.05456542969, -994.67736816406),
      vector2(-290.4270324707, -977.08093261719),
      vector2(-283.4645690918, -924.81988525391),
      vector2(-269.30850219727, -887.85803222656),
      vector2(-345.55624389648, -871.81787109375)
    }, {
      minZ = 30.0
    }),
  }, 
  parking34 = {
    name   = "Parking 34",
    fee    = 3000,
    entrances  = {
      vector3(130.75, -2536.38, 5.0)
    },
		maxcar = 10,
    zone = PolyZone:Create({
      vector2(148.78430175781, -2531.8173828125),
      vector2(152.84150695801, -2542.2097167969),
      vector2(75.531021118164, -2544.5634765625),
      vector2(70.752807617188, -2535.9296875),
      vector2(83.076271057129, -2518.3356933594),
      vector2(87.591773986816, -2522.1508789062)
    }, {
      minZ = 3.0
    })
  },
  parking949 = {
    name   = "Parking 949",
    fee    = 3000,
    entrances  = {
      vector3(1982.02, 3069.0, 46.0)
    },
		maxcar = 10,
    zone =  PolyZone:Create({
      vector2(2007.9705810547, 3046.9934082031),
      vector2(1998.4720458984, 3051.5361328125),
      vector2(1978.6236572266, 3062.908203125),
      vector2(1994.2033691406, 3088.3896484375),
      vector2(2024.9884033203, 3069.0803222656)
    }, {
      minZ = 43.0
    })
  },
  parking381 = {
    name   = "Parking 381",
    fee    = 2000,
    entrances  = {
      vector3(-351.56, -824.39, 30.5)
    },
		maxcar = 15,
    zone = PolyZone:Create({
      vector2(-335.12908935547, -825.25671386719),
      vector2(-364.66879272461, -826.15881347656),
      vector2(-362.58465576172, -707.59173583984),
      vector2(-339.78118896484, -707.66369628906),
      vector2(-332.00588989258, -682.35296630859),
      vector2(-290.8034362793, -682.67749023438),
      vector2(-267.15789794922, -750.18212890625)
    }, {
      minZ = 30.524620056152
    })
  }, 
  vinedos = {
    name = "Parking Vigne",
    entrances  = {
      vector3(-1874.54, 2038.6, 138.5),
      vector3(-1884.19, 2007.2, 140.5),
    },
    maxcar = 10,
    zone = PolyZone:Create({
      vector2(-1921.6291503906, 2061.9162597656),
      vector2(-1929.6076660156, 2028.6848144531),
      vector2(-1911.328125, 2023.2541503906),
      vector2(-1910.1420898438, 1996.9866943359),
      vector2(-1888.1898193359, 1998.5826416016),
      vector2(-1875.9741210938, 2044.0516357422)
    }, {
      minZ = 31.0
    }),
    jobs = { 'vignep' }
  },
  delivery = {
    name = "Parking d'entrepot",
    maxcar = 10,
    entrances  = {
      vector3(1176.27, -3242.90, 5.0),
    },
    zone = PolyZone:Create({
      vector2(1176.07, -3227.78),
      vector2(1195.71, -3227.36),
      vector2(1195.71, -3257.39),
      vector2(1176.85, -3259.11),
    }, {
      minZ = 4.0,
      -- debugGrid = true
    }),
    jobs = { 'delivery' }
  },
  concertHall = {
    name = "Parking 712",
    entrances  = {
      vector3(657.76, 637.13, 128.91)
    },
    maxcar = 10,
    zone = PolyZone:Create({
      vector2(648.55413818359, 581.9736328125),
      vector2(619.50964355469, 592.95727539062),
      vector2(638.25, 645.68426513672),
      vector2(667.80523681641, 634.09625244141)
    }, {
      minZ = 127.0
    })
  },
  bridgeFBI = {
    name = "Parking FIB",
    entrances  = {
      vector3(49.641, -842.167, 29.5), 
      vector3(57.3828, -882.703, 29.5)
    },
    maxcar = 10,
    zone = PolyZone:Create({
      vector2(32.62385559082, -836.03149414062),
      vector2(69.494132995605, -849.35815429688),
      vector2(61.985488891602, -869.7998046875),
      vector2(25.128923416138, -856.58984375)
    }, {
      minZ = 29.0
    })
  },
  observatory = {
    name = "Parking Observatoire",
    maxcar = 10,
    entrances  = {
      vector3(-2328.660, 307.502, 168.1),
    },
    zone = PolyZone:Create({
      vector2(-2337.0920410156, 304.27774047852),
      vector2(-2323.4580078125, 273.86706542969),
      vector2(-2307.0131835938, 281.20922851562),
      vector2(-2320.7348632812, 311.54330444336)
    }, {
      minZ = 29.0
    })
  },
  industrialNorte = {
    name = "Parking Industriel",
    maxcar = 10,
    entrances  = {
      vector3(2677.527, 1671.026, 23.4885),
    },
    zone = PolyZone:Create({
      vector2(2677.0991210938, 1657.7574462891),
      vector2(2655.9072265625, 1657.4002685547),
      vector2(2655.56640625, 1698.7482910156),
      vector2(2676.9838867188, 1698.9072265625)
    }, {
      minZ = 22.0
    })
  },
}


