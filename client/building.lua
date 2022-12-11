RegisterCommand('testgarage', function()
    LaunchBuild("garage")
end, false)

local heading = 0.0
local spawnveh = false
local veh = nil
local index = 1

local tabletest = {
    ["garage"] = {
        [1] = {
            name = 'spawnpoint',
            position = nil,
            marker = function(coords)
                DrawMarker(36, coords, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 150, false, true, 2, true, false, false, false)
				DrawMarker(25, vector3(coords.x, coords.y, coords.z - 0.5), 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 150, false, true, 2, true, false, false, false)			
            end
        },
        [2] = {
            name = 'deletepoint',
            position = nil,
            marker = function(coords)
                DrawMarker(5, coords, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 100, false, true, 2, true, false, false, false)
				DrawMarker(27, vector3(coords.x, coords.y, coords.z - 0.5), 0.0, 0.0, 0.0, 0, 0.0, 0.0, 3.0, 3.0, 1.0, 255, 255, 255, 100, false, true, 2, true, false, false, false)
	        end
        },
        [3] = {
            name = 'possiblespawn',
            position = {},
            marker = function(coords)
                if not spawnveh then
                    spawnveh = true
                    local hash = GetHashKey("sultan")
                    RequestModel(hash)
                    while not HasModelLoaded(hash) do
                        Citizen.Wait(1)
                    end
                    veh = CreateVehicle(hash, coords, 100.00, false, false)
                    SetEntityCollision(veh, false, false)
                    SetEntityAlpha(veh, 180, 0)
                end
                if IsControlPressed(0, 25) then
                    heading = heading + 0.75
                end
                if IsControlPressed(0, 348) then
                    heading = heading - 0.75
                end
                SetEntityHeading(veh, heading) 
                SetEntityCoords(veh, coords)
            end
        }
    },
    ["recover"] = {
        [1] = {
            name = 'spawnpoint',
            position = nil,
            marker = function(coords)
                DrawMarker(36, coords, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, 250, 250, 34, 100, false, true, 2, true, false, false, false)
                DrawMarker(43, vector3(coords.x, coords.y, coords.z - 1.0), 0.0, 0.0, 0.0, 0, 0.0, 0.0, 2.0, 2.0, 2.0, 250, 250, 34, 100, false, true, 2, true, false, false, false)
            end
        },
        [2] = {
            name = 'possiblespawn',
            position = {},
            marker = function(coords)
                if not spawnveh then
                    spawnveh = true
                    local hash = GetHashKey("sultan")
                    RequestModel(hash)
                    while not HasModelLoaded(hash) do
                        Citizen.Wait(1)
                    end
                    veh = CreateVehicle(hash, coords, 100.00, false, false)
                    SetEntityCollision(veh, false, false)
                    SetEntityAlpha(veh, 180, 0)
                end
                if IsControlPressed(0, 25) then
                    heading = heading + 0.75
                end
                if IsControlPressed(0, 348) then
                    heading = heading - 0.75
                end
                SetEntityHeading(veh, heading) 
                SetEntityCoords(veh, coords)
            end
        }
    }
}

function LaunchBuild(indication)
    local data = {}
    for i = 1, #tabletest[indication], 1 do
        data[tabletest[indication][i].name] = {}
    end
    inbuilding = true
    while inbuilding do
        local hit, coords, entity = RayCastGamePlayCamera(1000.0)
        local coords = vector3(coords.x, coords.y, coords.z + 1.0)
        tabletest[indication][index].marker(coords)

        if not tabletest[indication][index].name == 'possiblespawn' then
            if DoesEntityExist(veh) then
                DeleteEntity(veh)
                spawnveh = false
            end
        end

        if IsControlJustReleased(0, 38) then
            if tabletest[indication][index].name == 'possiblespawn' then
                local coordsVeh = GetEntityCoords(veh)
                local headingVeh = GetEntityHeading(veh)
                local coordsTable = vector4(coordsVeh.x, coordsVeh.y, coordsVeh.z, headingVeh)
                table.insert(data[tabletest[indication][index].name], coordsTable)
            else
                data[tabletest[indication][index].name] = coords
            end
        end

        if IsControlJustReleased(0, 83) then
            if index <= #tabletest[indication] and index + 1 <= #tabletest[indication] then
                index = index + 1
            end
        end

        if IsControlJustReleased(0, 202) then
            if index - 1 >= (#tabletest[indication] - #tabletest[indication] + 1) then
                index = index - 1
            end
        end

        if IsControlJustReleased(0, 18) then
            local contextinfo = exports["az_context"]:ShowContextMenu({
                title = 'Job setting', 
                field = 2,
                field1 = 'Job name :',
                field2 = 'Name garage :'
            })
            data["jobname"] = contextinfo[1].text
            data["name"] = contextinfo[2].text
            TriggerServerEvent('az_garage:setNewGarage', indication, data)
            inbuilding = false
        end

        Citizen.Wait(0)
    end
end

function RayCastGamePlayCamera(distance)
    -- https://github.com/Risky-Shot/new_banking/blob/main/new_banking/client/client.lua
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =
	{
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance
	}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
	return b, c, e
end


function RotationToDirection(rotation)
    -- https://github.com/Risky-Shot/new_banking/blob/main/new_banking/client/client.lua
	local adjustedRotation =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction =
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end