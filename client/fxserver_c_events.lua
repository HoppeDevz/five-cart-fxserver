RegisterNetEvent("fxserver_c_events:user-notify")
AddEventHandler("fxserver_c_events:user-notify", function(user_id, argument, amount, temporary)
    SendNUIMessage({
        action = "user-notify",
        user_id = user_id,
        product = argument,
        amount = amount,
        temporary = temporary,
    })
end)