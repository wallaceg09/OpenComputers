local component = require("component")

-- Returns all Thermal Expansion energy cells of a given component.
function getTECells(component)
	local teCellsRaw = component.list("energy_device")
	local teCells = {}

	local teCellCount = 0
	for address, name in pairs(teCellsRaw) do
		teCellCount = teCellCount + 1
		
		if teCellCount > 1 then
			teCells[address] = "Thermal Expansion Power Cell".." "..countTEcell
		else
			teCells[address] = "Thermal Expansion Power Cell"
		end
	end
	
	return teCells
end

-- Returns a tuple containing the current RF in all attached cells, and the 
-- maximum RF in all attached cells.
function getRF(teCells)
	local currentRF = 0
	local maxRF = 0
	
	for address, name in pairs(teCells) do
		local cell = component.proxy(address)
		currentRF = currentRF + cell.getEnergyStored()
		maxRF = maxRF + cell.getMaxEnergyStored()
	end
	
	return currentRF, maxRF
end

while true do
	local teCells = getTECells(component)
	local currentRF, maxRF = getRF(teCells)
	local percent = currentRF / maxRF
	print("Current RF: "..currentRF.." Max RF: "..maxRF.." Percent: "..percent)
end