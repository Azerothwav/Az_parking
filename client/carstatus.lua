local CarsOnEarth = {}

function AddCarOnEarth(plate, entity)
    table.insert(CarsOnEarth, { plate = plate, entity = entity })
end

function IsCarOnEarth(plate)
	if #CarsOnEarth > 0 then
		for k,v in pairs (CarsOnEarth) do
			if _Utils.Trim(v.plate) == _Utils.Trim(plate) then
				if DoesEntityExist(v.entity) then
					return true
				else
					table.remove(CarsOnEarth, k)
					return false
				end
			end
		end
	else
		return false
	end
end

function RemoveCarFromEarth(plate, entity)
	for k, v in pairs(CarsOnEarth) do
		if _Utils.Trim(v.plate) == _Utils.Trim(plate) then
			table.remove(CarsOnEarth, k)
		end
	end
end