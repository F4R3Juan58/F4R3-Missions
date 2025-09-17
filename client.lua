local missions = {}
local spawnedPeds = {}
local cooldowns = {}

-- 🔄 Cargar misiones al entrar
CreateThread(function()
    local result = lib.callback.await('F4R3-missions:getAll', false)
    if result then
        for id, mission in pairs(result) do
            spawnMissionNPC(mission)
        end
    end
end)

-- 🔄 Cuando se crea nueva misión (server -> client)
RegisterNetEvent('F4R3-missions:addMission', function(mission)
    missions[mission.id] = mission
    spawnMissionNPC(mission)

    -- 🔄 Refrescar NUI en tiempo real
    SendNUIMessage({
        action = 'missions',
        payload = missions
    })
end)

-- 🧍 Spawnear un NPC
function spawnMissionNPC(mission)
    if spawnedPeds[mission.id] then return end

    local model = mission.npc_model or "a_m_m_business_01"
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local ped = CreatePed(4, model, mission.x, mission.y, mission.z - 1, mission.heading, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)

    spawnedPeds[mission.id] = ped
    missions[mission.id] = mission

    if Config.Debug then
        print(("NPC de misión %s (%s) spawneado en %.2f %.2f %.2f"):format(
            mission.name, mission.type, mission.x, mission.y, mission.z
        ))
    end
end

-- 📍 Dibujar texto 3D
local function Draw3DText(coords, text, scale, color)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end
    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(color.r, color.g, color.b, color.a)
    SetTextCentre(1)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentString(text)
    EndTextCommandDisplayText(_x, _y)
end

-- 🎮 Loop de interacción
CreateThread(function()
    while true do
        local sleep = 1500
        local ped = cache.ped
        local coords = GetEntityCoords(ped)

        for id, mission in pairs(missions) do
            local npc = spawnedPeds[id]
            if npc and DoesEntityExist(npc) then
                local npcCoords = GetEntityCoords(npc)
                local dist = #(coords - npcCoords)

                if dist < Config.MarkerRadius then
                    sleep = 0
                    Draw3DText(npcCoords + vec3(0,0,1.0), Config.Marker.text, Config.Marker.scale, Config.Marker.color)

                    if dist < Config.InteractDistance and IsControlJustReleased(0, 38) then -- E
                        if not cooldowns[id] or (GetGameTimer() - cooldowns[id]) > Config.RobCooldown then
                            cooldowns[id] = GetGameTimer()
                            handleMissionInteraction(id, mission)
                        else
                            lib.notify({
                                title = "Cooldown",
                                description = "Debes esperar antes de volver a interactuar.",
                                type = "error",
                                position = "center"
                            })
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- 🤝 Ejecutar interacción según tipo
function handleMissionInteraction(id, mission)
    if mission.type == "interactivo" then
        playAnim(Config.Animations.interact.dict, Config.Animations.interact.anim, 5000)
        TriggerServerEvent("F4R3-missions:interact", id)
    elseif mission.type == "robable" then
        playAnim(Config.Animations.rob.dict, Config.Animations.rob.anim, 5000)
        TriggerServerEvent("F4R3-missions:rob", id)
    else
        lib.notify({
            title = "Error",
            description = "Este NPC no tiene interacción configurada.",
            type = "error",
            position = "center"
        })
    end
end

-- 🎬 Función para animaciones
function playAnim(dict, anim, duration)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    TaskPlayAnim(cache.ped, dict, anim, 2.0, 2.0, duration, 49, 0, false, false, false)
    Wait(duration)
    ClearPedTasks(cache.ped)
end


-----------------------------------
-- 📟 NUI: Gestión de Misiones
-----------------------------------

local nuiOpen = false

-- Abrir/Cerrar con tecla
RegisterCommand('openMissionsMenu', function()
    if nuiOpen then
        closeMissionsMenu()
    else
        openMissionsMenu()
    end
end, false)

RegisterKeyMapping('openMissionsMenu', 'Abrir menú de misiones', 'keyboard', Config.OpenMenuKey)

function openMissionsMenu()
    nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'showUI' }) -- muestra
    lib.callback('F4R3-missions:getAll', false, function(result)
        SendNUIMessage({
            action = 'missions',
            payload = result
        })
    end)
end

function closeMissionsMenu()
    nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' }) -- oculta
end

-- 📡 NUI → LUA

RegisterNUICallback('close', function(_, cb)
    closeMissionsMenu()
    cb(true)
end)

RegisterNUICallback('createMission', function(data, cb)
    -- Agregar coords donde está el jugador mirando
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    data.coords = {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = heading
    }

    TriggerServerEvent('F4R3-missions:create', data)
    cb(true)
end)

-----------------------------------
-- 🧍 Colocación de NPC (usando tus coords)
-----------------------------------

local placing = false
local placingModel = nil

RegisterNUICallback('startPlacement', function(data, cb)
    placingModel = data.model
    placing = true

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideUI' })

    cb(true)
    lib.notify({
        title = 'Modo colocación',
        description = 'Muévete al sitio donde quieras poner el NPC y pulsa ENTER.',
        type = 'inform'
    })
end)

CreateThread(function()
    while true do
        if placing then
            if IsControlJustReleased(0, 191) then -- Enter
                local pedCoords = GetEntityCoords(cache.ped)
                local heading = GetEntityHeading(cache.ped)

                -- Enviar a la NUI
                SendNUIMessage({
                    action = 'npcCoords',
                    payload = { x = pedCoords.x, y = pedCoords.y, z = pedCoords.z, w = heading }
                })

                -- Avisar al servidor para que cree el ped para todos
                TriggerServerEvent('F4R3-Missions:spawnPed', placingModel, pedCoords, heading)

                placing = false
                placingModel = nil

                -- Volver a mostrar menú
                SetNuiFocus(true, true)
                SendNUIMessage({ action = 'showUI' })

                lib.notify({
                    title = 'Colocación completada',
                    description = 'NPC colocado y visible para todos.',
                    type = 'success'
                })
            end
        end
        Wait(0)
    end
end)


RegisterNUICallback('updateMission', function(data, cb)
    -- Añadimos coords actuales si no se colocó un ped
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    if not data.coords then
        data.coords = { x = coords.x, y = coords.y, z = coords.z, w = heading }
    end

    TriggerServerEvent('F4R3-missions:update', data)
    cb(true)
end)

RegisterNetEvent('F4R3-Missions:createPed', function(model, coords, heading)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local ped = CreatePed(4, model, coords.x, coords.y, coords.z, heading or 0.0, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
end)

-- Abrir/Cerrar menú con F7
RegisterCommand('+openMissionsMenu', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'showUI' })
end, false)

RegisterCommand('-openMissionsMenu', function() end, false)

-- F7 = 168
RegisterKeyMapping('+openMissionsMenu', 'Abrir menú de misiones', 'keyboard', 'F7')

RegisterNetEvent('F4R3-missions:removeMission', function(id)
    if spawnedPeds[id] and DoesEntityExist(spawnedPeds[id]) then
        DeletePed(spawnedPeds[id])
    end
    spawnedPeds[id] = nil
    missions[id] = nil

    SendNUIMessage({
        action = 'missions',
        payload = missions
    })
end)

RegisterNUICallback('deleteMission', function(data, cb)
    if data.id then
        TriggerServerEvent('F4R3-missions:delete', data.id)
    end
    cb(true)
end)

RegisterCommand('openMissionsMenu', function()
    if nuiOpen then closeMissionsMenu()
    else openMissionsMenu() end
end, false)

RegisterKeyMapping('openMissionsMenu', 'Abrir menú de misiones', 'keyboard', Config.OpenMenuKey)
