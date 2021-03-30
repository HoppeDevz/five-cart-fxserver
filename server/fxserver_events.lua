local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

--------------------------------------------- ban/unban EVENTS --------------------------------------------------------
RegisterNetEvent("fxserver-events-ban")
AddEventHandler("fxserver-events-ban", function(user_id, argument, amount)
    local user_id = tonumber(user_id)
    local source = vRP.getUserSource(user_id)

    if source then
        vRP.kick(source, "Você foi banido do servidor pois pediu reembolso do unban.")
    end

    MySQL.Sync.fetchAll("UPDATE vrp_users SET banned = 1 WHERE id = @user_id", {
        ["@user_id"] = user_id
    })
end)

RegisterNetEvent("fxserver-events-unban")
AddEventHandler("fxserver-events-unban", function(user_id, argument, amount)
    local user_id = tonumber(user_id)
    local source = vRP.getUserSource(user_id)

    MySQL.Sync.fetchAll("UPDATE vrp_users SET banned = 0 WHERE id = @user_id", {
        ["@user_id"] = user_id
    })
end)

--------------------------------------------- group/ungroup EVENTS -----------------------------------------------
RegisterNetEvent("fxserver-events-group")
AddEventHandler("fxserver-events-group", function(user_id, argument, amount)
    local user_id = tonumber(user_id)
    local source = vRP.getUserSource(user_id)

    if source then
        vRP.addUserGroup(user_id, argument)
    else
        local rows = MySQL.Sync.fetchAll("SELECT * FROM vrp_user_data WHERE dkey = 'vRP:datatable' AND user_id = @user_id", {
            ["@user_id"] = user_id
        })
    
        if #rows > 0 then
            local parsed_dvalue = json.decode(rows[1].dvalue)
            parsed_dvalue.groups[argument] = true;

            MySQL.Sync.fetchAll("UPDATE vrp_user_data SET dvalue = @dvalue WHERE dkey = 'vRP:datatable' AND user_id = @user_id", {
                ['@dvalue'] = json.encode(parsed_dvalue),
                ['@user_id'] = user_id,
            })
        end
    end
    
end)

RegisterNetEvent("fxserver-events-ungroup")
AddEventHandler("fxserver-events-ungroup", function(user_id, argument, amount)
    local user_id = tonumber(user_id)
    local source = vRP.getUserSource(user_id)

    if source then
        vRP.removeUserGroup(user_id, argument)
    else
        local rows = MySQL.Sync.fetchAll("SELECT * FROM vrp_user_data WHERE dkey = 'vRP:datatable' AND user_id = @user_id", {
            ["@user_id"] = user_id
        })

        if #rows > 0 then
            local parsed_dvalue = json.decode(rows[1].dvalue)

            local pos = 1
            for k,v in pairs(parsed_dvalue.groups) do
                if k == argument then
                    parsed_dvalue.groups[k] = nil
                end
            end

            MySQL.Sync.fetchAll("UPDATE vrp_user_data SET dvalue = @dvalue WHERE dkey = 'vRP:datatable' AND user_id = @user_id", {
                ['@dvalue'] = json.encode(parsed_dvalue),
                ['@user_id'] = user_id,
            })
        end
    end
end)

--------------------------------------------- addMoney/removeMoney EVENTS -----------------------------------------------
RegisterNetEvent("fxserver-events-addBank")
AddEventHandler("fxserver-events-addBank", function(user_id, argument, amount)
    local user_id = tonumber(user_id)
    local source = vRP.getUserSource(user_id)

    if source then
        vRP.giveBankMoney(user_id, tonumber(argument))
    else
        MySQL.Sync.fetchAll("UPDATE vrp_user_moneys SET bank = bank + @incrementval WHERE user_id = @user_id", {
            ['@user_id'] = user_id,
            ['@incrementval'] = tonumber(argument),
        })
    end
end)

RegisterNetEvent("fxserver-events-removeBank")
AddEventHandler("fxserver-events-removeBank", function(user_id, argument, amount)
    local user_id = tonumber(user_id)
    local source = vRP.getUserSource(user_id)

    if source then
        --if not vRP.tryFullPayment(user_id, tonumber(argument)) then
            vRP.setBankMoney(user_id, vRP.getBankMoney(user_id) - tonumber(argument))
        --end
    else
        MySQL.Sync.fetchAll("UPDATE vrp_user_moneys SET bank = bank - @incrementval WHERE user_id = @user_id", {
            ['@user_id'] = user_id,
            ['@incrementval'] = tonumber(argument),
        })
    end
end)

------------------------------------------ addInventory/removeInventory-----------------------------------------------
RegisterNetEvent("fxserver-events-addInventory")
AddEventHandler("fxserver-events-addInventory", function(user_id, argument, amount)
    local user_id = tonumber(user_id)
    local source = vRP.getUserSource(user_id)

    if source then
        vRP.giveInventoryItem(user_id, argument, amount, false)
    else
        local rows = MySQL.Sync.fetchAll("SELECT * FROM vrp_user_data WHERE dkey = 'vRP:datatable' AND user_id = @user_id", {
            ["@user_id"] = user_id
        })
    
        if #rows > 0 then
            local parsed_dvalue = json.decode(rows[1].dvalue)

            if parsed_dvalue.inventory[argument] then
                parsed_dvalue.inventory[argument] = parsed_dvalue.inventory[argument] + amount;
            else
                parsed_dvalue.inventory[argument] = amount
            end

            MySQL.Sync.fetchAll("UPDATE vrp_user_data SET dvalue = @dvalue WHERE dkey = 'vRP:datatable' AND user_id = @user_id", {
                ['@dvalue'] = json.encode(parsed_dvalue),
                ['@user_id'] = user_id,
            })
        end
    end
end)

RegisterNetEvent("fxserver-events-removeInventory")
AddEventHandler("fxserver-events-removeInventory", function(user_id, argument, amount)
    local user_id = tonumber(user_id)
    local source = vRP.getUserSource(user_id)

    if source then
        local item_amount = vRP.getInventoryItemAmount(user_id, argument)
        if not vRP.tryGetInventoryItem(user_id, argument, amount, false) then
            vRP.tryGetInventoryItem(user_id, argument, item_amount, false)
        end
    else
        local rows = MySQL.Sync.fetchAll("SELECT * FROM vrp_user_data WHERE dkey = 'vRP:datatable' AND user_id = @user_id", {
            ["@user_id"] = user_id
        })

        if #rows > 0 then
            local parsed_dvalue = json.decode(rows[1].dvalue)

            if parsed_dvalue.inventory[argument] then
                if parsed_dvalue.inventory[argument] - amount > 0 then
                    parsed_dvalue.inventory[argument] = parsed_dvalue.inventory[argument] - amount
                else
                    parsed_dvalue.inventory[argument] = nil
                end
            end

            MySQL.Sync.fetchAll("UPDATE vrp_user_data SET dvalue = @dvalue WHERE dkey = 'vRP:datatable' AND user_id = @user_id", {
                ['@dvalue'] = json.encode(parsed_dvalue),
                ['@user_id'] = user_id,
            })
        end
    end
end)

------------------------------------------ addHome/removeHome ----------------------------------------------------------
RegisterNetEvent("fxserver-events-addHome")
AddEventHandler("fxserver-events-addHome", function(user_id, argument, amount)
    local user_id = tonumber(user_id)
    local source = vRP.getUserSource(user_id)

    if source then
        local number = vRP.findFreeNumber(argument, 1000)
        vRP.setUserAddress(user_id, argument, number)
    else
        local number = vRP.findFreeNumber(argument, 1000)
        MySQL.Sync.fetchAll("INSERT INTO vrp_user_homes (user_id, home, number, chest) VALUES(@user_id, @home, @number, @chest)", {
            ["@user_id"] = user_id,
            ["@home"] = argument,
            ["@number"] = number,
            ["@chest"] = json.encode({});
        })
    end
end)

RegisterNetEvent("fxserver-events-removeHome")
AddEventHandler("fxserver-events-removeHome", function(user_id, argument, amount)
    local user_id = tonumber(user_id)
    local source = vRP.getUserSource(user_id)

    if source then
        vRP.removeUserAddress(user_id, argument)
    else
        MySQL.Sync.fetchAll("DELETE FROM vrp_user_homes WHERE user_id = @user_id AND home = @home", {
            ["@user_id"] = user_id,
            ["@home"] = argument,
        })
    end
end)

------------------------------------------ addVehicle/removeVehicle ----------------------------------------------------------
RegisterNetEvent("fxserver-events-addVehicle")
AddEventHandler("fxserver-events-addVehicle", function(user_id, argument, amount)
    local user_id = tonumber(user_id)
    local source = vRP.getUserSource(user_id)
    
    MySQL.Sync.fetchAll("INSERT INTO vrp_user_vehicles (user_id, vehicle) VALUES(@user_id, @vehicle)", {
        ["@user_id"] = user_id,
        ["@vehicle"] = argument
    })
end)

RegisterNetEvent("fxserver-events-removeVehicle")
AddEventHandler("fxserver-events-removeVehicle", function(user_id, argument, amount)
    local user_id = tonumber(user_id)
    local source = vRP.getUserSource(user_id)

    MySQL.Sync.fetchAll("DELETE FROM vrp_user_vehicles WHERE user_id = @user_id AND vehicle = @vehicle", {
        ["@user_id"] = user_id,
        ["@vehicle"] = argument
    })
end)