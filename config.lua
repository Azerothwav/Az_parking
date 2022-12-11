Config = {}

Config.FrameWork = "ESX" -- ESX, QBCore or custom

Config.UseLegacyFuel = false
Config.RecoverBasePrice = 300
Config.StoreOnServerStart = true
Config.UseBtTarget = false
Config.TargetRessource = "qb-target"
Config.UseAz_Vehicle = false

Config.PlayerIdentifier = function()
	if Config.FrameWork == "ESX" then
		return ESX.PlayerData.identifier
	elseif Config.FrameWork == "QBCore" then
		if PlayerData ~= nil then
			return PlayerData.license
		else
			return ''
		end
	end
end

Config.GiveKey = function(plate)
	if Config.FrameWork == "ESX" then
		
	elseif Config.FrameWork == "QBCore" then
		TriggerEvent("vehiclekeys:client:SetOwner", plate)
	end
end

Config.Job = {
	["name"] = {
		["job1"] = function()
			if Config.FrameWork == "ESX" then
				return ESX.PlayerData.job.name
			elseif Config.FrameWork == "QBCore" then
				return PlayerJob.name
			end
		end,
		["job2"] = function()
			if Config.FrameWork == "ESX" then
				return ESX.PlayerData.job2.name
			elseif Config.FrameWork == "QBCore" then
				return PlayerJob.name
			end
		end,
		--[[["job3"] = function()
			if Config.FrameWork == "ESX" then
				return ESX.PlayerData.job3.name
			elseif Config.FrameWork == "QBCore" then
				return PlayerJob.name
			end
		end]]
	},
	["grade"] = {
		["grade1"] = function()
			if Config.FrameWork == "ESX" then
				return ESX.PlayerData.job.grade_label
			elseif Config.FrameWork == "QBCore" then
				return PlayerJob.grade.name
			end
		end,
		["grade2"] = function()
			if Config.FrameWork == "ESX" then
				return ESX.PlayerData.job2.grade_label
			elseif Config.FrameWork == "QBCore" then
				return PlayerJob.grade.name
			end
		end,
		--[[["grade3"] = function()
			if Config.FrameWork == "ESX" then
				return ESX.PlayerData.job3.grade_label
			elseif Config.FrameWork == "QBCore" then
				return PlayerJob.grade.name
			end
		end]]
	}
}

Config.Lang = {
	["car_broken"] = "Your car is in too bad condition",
	["car_save"] = "Your car is stored",
	["car_error"] = "Your car can't be stored",
	["no_place"] = "No place for your car",
	["no_vehicle"] = "No vehicle found",
	["delete_help"] = "Press E to park your vehicle",
	["spawn_help"] = "Press E to take a vehicle",
	["recover_help"] = "Press E to open the impound",
	["cant_access"] = "You can't access it",
	["not_in_a_vehicle"] = "You are not in a vehicle",
	["cant_in_a_vehicle"] = "You are in a vehicle",
	["car_out"] = "Your car was taken out",
	["vehicle_on_map"] = "The vehicle is already in town",
	["not_boss"] = "You are not a boss",
	["steal_vip"] = "You can't steal a VIP vehicle",
	["job_vehicle"] = "You can't bring this vehicle here",
	["not_enought_money"] = "You don't have enough money",
	["vehicle_already_out"] = "Vehicle already out",
	["rename_vehicle"] = "Rename your vehicle",
	["get_out_vehicle"] = "Take your vehicle out",
	["transfert_vehicle"] = "Transferer son véhicule",

	["public_recover"] = "Public pound",
	["private_recover"] = "Private pound",
	["public_garage"] = "Public garage",
	["private_garage"] = "Private garage",

	--Stolen Garage
	["stolen_garage_help"] = "Press E to open the garage",

	-- Target part
	["see_vehicle"] = "Browse the vehicles",
	["see_recover_vehicle"] = "Browse the pound",
	["put_in_garage"] = "Put your vehicle away"
}