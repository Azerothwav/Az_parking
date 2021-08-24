Config = {}

Config.Debug = false
Config.Locale = 'fr'
Config.UseLegacyFuel = false -- Use false for esx_legacyfuel
Config.LegacyFuelResName = "LegacyFuel" -- LegacyFuel resource folder name
Config.MinParkingPrice = 0
Config.RecoverBasePrice = 80000
Config.RecoverRate = 0.1
Config.VehicleNameColumn = 'owned_vehicles' -- Name at database to get vehicle name
Config.EnableCivJob = true -- Vehicles without job has 'civ' at database
Config.CivJob = 'civ' -- EnableCivJob must be true to work
Config.StoreJobCarsGarage = 'central'
Config.UseAdvencedNotification = true
Config.CharGarage = 'CHAR_MP_MORS_MUTUAL'
Config.PrintCarStored = false

Config.Colors = {
	plate = '#d1af15',	
	pound = '#c42f0a',	
	parking = '#abc900',	
	stored = '#51ab07',	
	outside = '#238fe8',
	prices = '#fff828',	
}

-- Real Parking Menu
Config.CarMenu = {
	ColdDown = 360,
	Command = 'cars',
	ValetPed = 'cs_movpremmale',
	ValetPricePerMeter = 0.8,
	ValetPrice = function(player, place)
		return math.floor(CalculateTravelDistanceBetweenPoints(player, place) * Config.CarMenu.ValetPricePerMeter)
	end
}

-- Real Parking Impound Configs
Config.Impound = {
	DrawDistance = 35.0, -- Marker distance draw
	Command = "decomisar", -- Impound command (check user job)
	AuthorizedJobs = { 'police' }, -- Table of string jobnames
	Society = 'society_police',
	ParkingFee = 500, -- Per day
	Rules = {
		minFee			= 1000,
		maxFee 			= 15000,
		minReasonLength	= 5,
	},
	Marker = {
		name = _U('warehouse_menu'),
		size = 0.3,
		color = { r = 37, g = 230, b = 34},
		type = 24
	},
	Blip = {
		sprite = 645,
		color = 69,
		size = 1.0		
	}
}

-- Real Parking Configs
Config.RealParking = {
	Type = 2,
	ShowEntrances = true,
	ShowCarInfo = true,
	RenderDistance = 5.0, -- How close do you need to render each parking zone cars
	EntrancesDrawDistance = 40.0, -- How close do you need to be for the entrances to be drawn (in GTA units).
	DrawDistance = 2.5, -- How close do you need to be for the plates to be drawn (in GTA units).
	DefaultMaxCar = 25, -- Default max car per parking
	MaxModels = 10,
	PublicParkingBlip = {
		sprite = 357,
		color = 25,
		size = 0.3
	},
	FreeParkingBlip = {
		sprite = 357,
		color = 66,
		size = 0.3
	},
	PrivateParkingBlip = {
		sprite = 357,
		color = 75,
		size = 0.3
	}
}

-- Traditional Garages Config
Config.Garages = {
	Type = 1,
	ShowTitle = true,
	DrawDistance = 20.0, -- Marker distance draw
	PublicGarageBlip = {
		sprite = 289,
		color = 25,
		size = 0.5
	},
	FreeGarageBlip = {
		sprite = 289,
		color = 66,
		size = 0.5
	},
	PrivateGarageBlip = {
		sprite = 289,
		color = 75,
		size = 0.0
	},
	SpawnMarker = {
		size = 1.0,
		color = { r = 255, g = 255, b = 255},
		type = 36
	},
	DeleteMarker = {
		size = 1.0,
		color = { r = 255, g = 255, b = 255},
		type = 5
	},
}

-- Car Recover Points
Config.RecoverPoints = {
	Society = "society_police",
	ShowTitle = true,
	DrawDistance = 30.0, -- Marker distance draw
	Blip = {
		name = 'Fourriere',
		sprite = 380,
		color = 57,
		size = 1.0
	},
	Marker = {
		size = 2.0,
		color = { r = 250, g = 250, b = 34},
		type = 36
	},
}