ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('wert-notes:get-my-notes', function(source, cb)
    local ply = ESX.GetPlayerFromId(source)
    if ply then
        MySQL.Async.fetchAll('SELECT * FROM notepad WHERE citizenid = @citizenid', {
            ['@citizenid'] = ply.getIdentifier()
        }, function (result)
            if result and result[1] then
                cb(result)
            else
                cb(nil)
            end
        end)
    else
        cb(nil)
    end
end)

RegisterNetEvent("wert-notes:server:new-note", function(text)
    local src = source
    local ply = ESX.GetPlayerFromId(source)
    if ply and text then
        MySQL.Async.execute('INSERT INTO notepad (citizenid, text) VALUES (@citizenid, @text)',{
		    ["@citizenid"] = ply.getIdentifier(),
            ["@text"] = text,
	    }, function (rowsChanged)
	    end)
    end
end)

RegisterNetEvent("wert-notes:server:save-note", function(id, text)
    local src = source
    local ply = ESX.GetPlayerFromId(source)
    if ply and id and text then
        TriggerClientEvent("esx:showNotification", src, "Note updated!")
        MySQL.Async.execute('UPDATE notepad SET text=@text WHERE id=@id', {
            ['@text'] = text,
            ['@id'] = id
        }, function (rowsChanged)
        end)
    end
end)

RegisterNetEvent("wert-notes:server:delete-note", function(id)
    local src = source
    if id then
        TriggerClientEvent("esx:showNotification", src, "Note deleted!")
        MySQL.Async.execute('DELETE FROM notepad WHERE id=@id', {
            ['@id'] = id
        }, function (rowsChanged)
        end)
    end
end)

RegisterNetEvent("wert-notes:server:share-note", function(id, text, playerId)
    local src = source
    local ply = ESX.GetPlayerFromId(src)
    local trgt = ESX.GetPlayerFromId(playerId)
    if ply and trgt and id and text then
        MySQL.Async.execute('INSERT INTO notepad (citizenid, text) VALUES (@citizenid, @text)',{
		    ["@citizenid"] = trgt.getIdentifier(),
            ["@text"] = text,
	    }, function (rowsChanged)
            TriggerClientEvent("esx:showNotification", ply.source, " You gave your #" .. id .. " numbered note to the nearby player!")
            TriggerClientEvent("esx:showNotification", trgt.source, "You got a note!")
	    end)
    end
end)

ESX.RegisterUsableItem("stickynote", function(source, item)
    local src = source
    TriggerClientEvent("wert-notes:client:use-item", src)
end)