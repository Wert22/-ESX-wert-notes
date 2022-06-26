ESX = nil
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(200)
    end
end)
local noteActive = false
local PlayerProps = {}

function GetPlayersFromCoords(coords, distance)
    local players = GetActivePlayers()
    local ped = PlayerPedId()
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    local distance = distance or 5
    local closePlayers = {}
    for _, player in pairs(players) do
        local target = GetPlayerPed(player)
        local targetCoords = GetEntityCoords(target)
        local targetdistance = #(targetCoords - coords)
        if targetdistance <= distance then
            closePlayers[#closePlayers + 1] = player
        end
    end
    return closePlayers
end

function GetClosestPlayer(coords)
    local ped = PlayerPedId()
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    local closestPlayers = GetPlayersFromCoords(coords)
    local closestDistance = -1
    local closestPlayer = -1
    for i = 1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() and closestPlayers[i] ~= -1 then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end

local function SharedRequestAnimDict(animDict, cb)
	if not HasAnimDictLoaded(animDict) then
		RequestAnimDict(animDict)

		while not HasAnimDictLoaded(animDict) do
			Citizen.Wait(1)
		end
	end
	if cb ~= nil then
		cb()
	end
end

local function AnimationActions(type)
    if type == "start" then
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        if DoesEntityExist(ped) and not IsEntityDead(ped) then 
            local x,y,z = table.unpack(pedCoords)
            local one = CreateObject(GetHashKey('prop_notepad_01'), x, y, z+0.2,  true,  true, true)
            PlayerProps[#PlayerProps+1] = one
            local two = CreateObject(GetHashKey('prop_pencil_01'), x, y, z+0.2,  true,  true, true)
            PlayerProps[#PlayerProps+1] = two
            AttachEntityToEntity(one, ped, GetPedBoneIndex(ped, 18905), 0.1, 0.02, 0.05, 10.0, 0.0, 0.0, true, true, false, true, 1, true)
            AttachEntityToEntity(two, ped, GetPedBoneIndex(ped, 58866), 0.12, 0.0, 0.001, -150.0, 0.0, 0.0, true, true, false, true, 1, true)
            SharedRequestAnimDict("missheistdockssetup1clipboard@base", function()
                TaskPlayAnim(ped, "missheistdockssetup1clipboard@base", "base", 8.0, 1.0, -1, 49, 0, 0, 0, 0 )  
            end)
        end
    elseif type == "end" then
        for k,v in pairs(PlayerProps) do
            DeleteEntity(v)
        end
        Wait(100)
        PlayerProps = {}
        ClearPedTasks(PlayerPedId())
    end
end

local function fullclose()
    if noteActive then 
        SetNuiFocus(false, false)
        noteActive = false 
        AnimationActions("end")
        SendNUIMessage({
            action = "close"
        })
    end
end

RegisterNetEvent("wert-notes:client:use-item", function()
    if not noteActive then
        noteActive = true
        AnimationActions("start")
        TriggerEvent("wert-notes:client:open-menu")
    end
end)


RegisterNetEvent("wert-notes:client:open-menu", function()
    local Menu = {
        {
            header = "Notebook",
            icon = "fa-solid fa-clipboard",
            isMenuHeader = true
        }
    }
    Menu[#Menu+1] = {
        header = "My notes",
        txt = "Look my notes",
        icon = "fa-solid fa-square-caret-right",
        params = {
            event = "wert-notes:client:select-action",
            args = {
                action = "mynotes"
            }
        }
    }
    Menu[#Menu+1] = {
        header = "Create new note",
        txt = "Open a white paper",
        icon = "fa-solid fa-square-caret-right",
        params = {
            event = "wert-notes:client:select-action",
            args = {
                action = "newnote"
            }
        }
    }
    Menu[#Menu+1] = {
        header = "Close",
        txt = "",
        icon = "fa-solid fa-circle-xmark",
        params = {
            event = "qb-menu:client:closeMenu"
        }
    }
    exports['qb-menu']:openMenu(Menu)
end)

RegisterNetEvent("wert-notes:client:select-action", function(data)
    local type = data.action
    if type == "newnote" then
        SendNUIMessage({
            action = "open"
        })
        SetNuiFocus(true, true)
    elseif type == "mynotes" then
        ESX.TriggerServerCallback('wert-notes:get-my-notes', function(result)
            if result then
                local Menu = {
                    {
                        header = "Saved notes",
                        icon = "fa-solid fa-clipboard",
                        isMenuHeader = true
                    }
                }
                for k,v in pairs(result) do
                    local test = v.text
                    if string.len(v.text) > 10 then
                        test = string.sub(v.text, 1, 10) .. "..."
                    end
                    Menu[#Menu+1] = {
                        header = test,
                        txt = "#".. k .. " Numbered note",
                        icon = "fa-solid fa-square-caret-right",
                        params = {
                            event = "wert-notes:client:opensavednot",
                            args = {
                                text = v.text,
                                id = v.id
                            }
                        }
                    }
                end
                Menu[#Menu+1] = {
                    header = "Close",
                    txt = "",
                    icon = "fa-solid fa-circle-xmark",
                    params = {
                        event = "qb-menu:client:closeMenu"
                    }
                }
                exports['qb-menu']:openMenu(Menu)
            else
                fullclose()
                ESX.ShowNotification('You dont have any saved note!', false, true)
            end
        end)
    end
end)

RegisterNetEvent("wert-notes:client:opensavednot", function(data)
    if data.text and data.id then
        SendNUIMessage({
            action = "load",
            id = data.id,
            text = data.text
        })
        SetNuiFocus(true, true)
    end
end)

RegisterNetEvent("qb-menu:client:closeMenu", function() if noteActive then noteActive = false AnimationActions("end") end end)
RegisterNetEvent("wert-notes:client:qb-menu-close", function() if noteActive then noteActive = false AnimationActions("end") end end)

--Callbacks
RegisterNUICallback("close", function()
    if noteActive then 
        SetNuiFocus(false, false)
        noteActive = false 
        AnimationActions("end") 
    end
end)

RegisterNUICallback("new-note", function(data)
    if data.text then
        fullclose()
        TriggerServerEvent("wert-notes:server:new-note", tostring(data.text))
    end
end)

RegisterNUICallback("save-note", function(data)
    if data.id and data.text then
        fullclose()
        TriggerServerEvent("wert-notes:server:save-note", tonumber(data.id), tostring(data.text))
    end
end)

RegisterNUICallback("delete-note", function(data)
    if data.id then
        fullclose()
        TriggerServerEvent("wert-notes:server:delete-note", tonumber(data.id))
    end
end)

RegisterNUICallback("share-note", function(data)
    if data.id then
        fullclose()
        local player, distance = GetClosestPlayer()
        if player ~= -1 and distance < 3.0 then
            local playerId = GetPlayerServerId(player)
            TriggerServerEvent("wert-notes:server:share-note", tonumber(data.id), tostring(data.text), playerId)
        else
            ESX.ShowNotification("No player by closest", false, true)
        end
    end
end)

RegisterNUICallback("notify", function(data)
    ESX.ShowNotification(data.notif, false, true)
end)
