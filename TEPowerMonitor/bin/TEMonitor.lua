local component = require("component")
local event = require("event")
local charts = require("charts")
local term = require("term")
local sides = require("sides")

-- TODO: Make this configurable...
local redstoneAddress = "9d11b857"
local redstoneSide = "back"

-- Returns all Thermal Expansion energy cells of a given component.
function getTECells(component)
    local teCellsRaw = component.list("energy_device")
    local teCells = {}

    local teCellCount = 0
    for address, name in pairs(teCellsRaw) do
        teCellCount = teCellCount + 1

        if teCellCount > 1 then
            teCells[address] = "Thermal Expansion Power Cell" .. " " .. countTEcell
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

function redstoneOn(redstoneProxy, side)
    if redstoneProxy ~= nil and side ~= nil then
        -- TODO: Make output configurable
        redstoneProxy.setOutput(side, 100)
    end
end

function redstoneOff(redstoneProxy, side)
    if redstoneProxy ~= nil and side ~= nil then
        -- TODO: Make output configurable
        redstoneProxy.setOutput(side, 0)
    end
end

function clearRedstone(redstoneProxy)
    for i = 0, 5 do
        redstoneOff(redstoneProxy, i)
    end
end

-- Estimates the number of seconds before all power will be drained.
function getETA(delta, remaining)
    if delta == 0 then
        return 0
    else
        return remaining / delta
    end
end

local container = charts.Container {
    x = 1,
    y = 1,
    width = 50,
    height = 2,
    payload = charts.ProgressBar {
        direction = charts.sides.RIGHT,
        value = 0,
        colorFunc = function(_, perc)
            return 0x20afff
        end
    }
}

local redstoneComponent = component.get(redstoneAddress)
local redstoneProxy = component.proxy(redstoneComponent)

redstoneOff(redstoneProxy)

local previousRF = 0
while true do
    local keyDownEvent = event.pull(1, "interrupted")

    if keyDownEvent ~= nil then
        term.clear()
        break
    end

    local teCells = getTECells(component)
    local currentRF, maxRF = getRF(teCells)
    local percent = currentRF / maxRF

    -- TODO: Make thresholds configurable.
    if percent > .9 then
        redstoneOff(redstoneProxy, sides[redstoneSide])
    elseif percent < .75 then
        redstoneOn(redstoneProxy, sides[redstoneSide])
    end

    term.clear()
    container.payload.value = percent

    local percentString = string.format("%6.2f", percent * 100)
    local deltaRF = currentRF - previousRF

    local eta = 0

    if deltaRF < 0 then
        eta = getETA(deltaRF, currentRF)
    elseif deltaRF > 0 then
        eta = getETA(deltaRF, maxRF - currentRF)
    end

    container.gpu.set(5, 4, "Current RF: " .. currentRF .. "(" .. percentString .. "%)")
    container.gpu.set(5, 5, "Max RF: " .. maxRF)
    container.gpu.set(5, 6, "Delta RF/s: " .. deltaRF)
    -- TODO: ETA on how many hours/mins/seconds until it's drained?
    local etaString = "Power ETA "
    if eta < 0 then
        etaString = etaString .. "Empty: "
    else
        etaString = etaString .. "Full: "
    end

    etaString = etaString .. math.abs(eta) .. " seconds"
    container.gpu.set(5, 7, etaString)

    container:draw()
    previousRF = currentRF
end