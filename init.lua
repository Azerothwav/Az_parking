GaragesDataJSON = {}
Recovers = {}
RageMenu = {}
RageMenu.Menu = {}
PlayerJob = {}
PlayerGang = {}
PlayerData = {}
if Config.FrameWork == "ESX" then
	ESX	= nil

	Citizen.CreateThread(function()
		while ESX == nil do
			TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
			Citizen.Wait(5)
		end
		while ESX.GetPlayerData().job == nil do
			Citizen.Wait(50)
		end
		PlayerData = ESX.GetPlayerData()
	end)

	RegisterNetEvent('esx:playerLoaded')
	AddEventHandler('esx:playerLoaded', function(xPlayer)
		ESX.PlayerData = xPlayer
		ChargeData()
	end)

	RegisterNetEvent('esx:setJob')
	AddEventHandler('esx:setJob', function(job)
		ESX.PlayerData.job = job
		LaunchBlips()
	end)

	RegisterNetEvent('esx:setJob2')
	AddEventHandler('esx:setJob2', function(job2)
		ESX.PlayerData.job2 = job2
		LaunchBlips()
	end)

	RegisterNetEvent('esx:setJob3')
	AddEventHandler('esx:setJob3', function(job3)
		ESX.PlayerData.job3 = job3
		LaunchBlips()
	end)
elseif Config.FrameWork == "QBCore" then
	QBCore = exports['qb-core']:GetCoreObject()

	AddEventHandler('onResourceStart', function(resourceName)
		if (GetCurrentResourceName() == resourceName) then
			PlayerData = QBCore.Functions.GetPlayerData()
			PlayerJob = PlayerData.job
			PlayerGang = PlayerData.gang
		end
	end)

	AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
		PlayerData = QBCore.Functions.GetPlayerData()
		PlayerJob = PlayerData.job
		PlayerGang = PlayerData.gang
		ChargeData()
	end)

	RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
		PlayerGang = gang
		LaunchBlips()
	end)
	
	RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
		PlayerJob = job
		LaunchBlips()
	end)
end