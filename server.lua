local QBX = exports.qbx_core
local missions = {} -- cache de misiones

-- 📦 Cargar todas las misiones al iniciar el recurso
CreateThread(function()
    local result = MySQL.query.await("SELECT * FROM missions", {})
    if result and #result > 0 then
        for _, row in ipairs(result) do
            missions[row.id] = row
        end
    end
    if Config.Debug then
        print(("Cargadas %s misiones desde la base de datos."):format(#result))
    end
end)

-- 📡 Enviar todas las misiones a un cliente que entra
lib.callback.register('F4R3-missions:getAll', function(src)
    return missions
end)

-- 📡 Crear nueva misión (admin)
RegisterNetEvent('F4R3-missions:create', function(data)
    local src = source
    if not IsPlayerAceAllowed(src, "missions.manage") and not IsPlayerAceAllowed(src, "command") then
        return
    end

    -- Insertar en DB
    local id = MySQL.insert.await([[
        INSERT INTO missions (name, type, npc_model, x, y, z, heading, config)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.name,
        data.type,
        data.npc_model or "a_m_m_business_01",
        data.coords.x,
        data.coords.y,
        data.coords.z,
        data.coords.w,
        json.encode(data.config or {})
    })

    if id then
        data.id = id
        missions[id] = data
        -- Reenviar a todos los clientes
        TriggerClientEvent('F4R3-missions:addMission', -1, data)
        if Config.Debug then print(('Misión %s creada por %s'):format(data.name, src)) end
    end
end)

-- 🎒 Interacción con NPC interactivo
RegisterNetEvent('F4R3-missions:interact', function(missionId)
    local src = source
    local Player = QBX:GetPlayer(src)
    local mission = missions[missionId]
    if not mission then return end

    local cfg = json.decode(mission.config or "{}")
    if mission.type == 'interactivo' and cfg.require and cfg.reward then
        -- Verificar requisitos
        for item, amount in pairs(cfg.require) do
            if exports.ox_inventory:Search(src, 'count', item) < amount then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Interacción fallida',
                    description = 'No tienes lo que se requiere',
                    type = 'error',
                    position = 'center'
                })
                return
            end
        end

        -- Quitar items requeridos
        for item, amount in pairs(cfg.require) do
            exports.ox_inventory:RemoveItem(src, item, amount)
        end

        -- Dar recompensa
        for item, amount in pairs(cfg.reward) do
            exports.ox_inventory:AddItem(src, item, amount)
        end

        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Interacción completada',
            description = 'Has recibido tu recompensa',
            type = 'success',
            position = 'center'
        })
    end
end)

-- 💰 Robo a NPC
RegisterNetEvent('F4R3-missions:rob', function(missionId)
    local src = source
    local Player = QBX:GetPlayer(src)
    local mission = missions[missionId]
    if not mission then return end

    local cfg = json.decode(mission.config or "{}")
    if mission.type == 'robable' and cfg.loot then
        for _, loot in ipairs(cfg.loot) do
            local chance = math.random(100)
            if chance <= (loot.chance or 100) then
                exports.ox_inventory:AddItem(src, loot.item, loot.amount)
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Robo exitoso',
                    description = ('Has conseguido %s x%s'):format(loot.item, loot.amount),
                    type = 'success',
                    position = 'center'
                })
            else
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Robo fallido',
                    description = 'No conseguiste nada',
                    type = 'error',
                    position = 'center'
                })
            end
        end

        -- Aviso a la policía
        if Config.AlertPoliceOnRob and math.random(100) <= Config.AlertPoliceChance then
            local coords = vector3(mission.x, mission.y, mission.z)
            TriggerEvent('F4R3-police:notify', {
                title = 'Robo a NPC',
                description = 'Un ciudadano ha intentado robar a un NPC',
                coords = coords
            })
        end
    end
end)


-- ✏️ Editar misión existente (admin)
RegisterNetEvent('F4R3-missions:update', function(data)
    local src = source
    local Player = QBX:GetPlayer(src)
    if not Player or Player.PlayerData.job.name ~= 'admin' then
        if Config.Debug then print(('Jugador %s intentó editar misión sin permisos'):format(src)) end
        return
    end

    if not data.id then
        if Config.Debug then print('Falta ID en update de misión') end
        return
    end

    -- Update en DB
    local updated = MySQL.update.await([[
        UPDATE missions
        SET name = ?, type = ?, npc_model = ?, x = ?, y = ?, z = ?, heading = ?, config = ?
        WHERE id = ?
    ]], {
        data.name,
        data.type,
        data.npc_model or "a_m_m_business_01",
        data.coords and data.coords.x or 0.0,
        data.coords and data.coords.y or 0.0,
        data.coords and data.coords.z or 0.0,
        data.coords and data.coords.w or 0.0,
        json.encode(data.config or {}),
        data.id
    })

    if updated and updated > 0 then
        missions[data.id] = data
        -- Reenviar lista actualizada a todos
        TriggerClientEvent('F4R3-missions:addMission', -1, data)
        if Config.Debug then print(('Misión #%s actualizada por %s'):format(data.id, src)) end
    else
        if Config.Debug then print(('Error al actualizar misión #%s'):format(data.id)) end
    end
end)

RegisterNetEvent('F4R3-Missions:spawnPed', function(model, coords, heading)
    local src = source

    -- Aseguramos modelo válido
    if not model or model == '' then return end

    -- Reenviar a todos los clientes para que creen el ped
    TriggerClientEvent('F4R3-Missions:createPed', -1, model, coords, heading)
end)

RegisterNetEvent('F4R3-missions:delete', function(id)
    local src = source
    if not IsPlayerAceAllowed(src, "missions.manage") then return end
    if not missions[id] then return end

    local deleted = MySQL.update.await("DELETE FROM missions WHERE id = ?", { id })
    if deleted and deleted > 0 then
        missions[id] = nil
        TriggerClientEvent('F4R3-missions:removeMission', -1, id)
        if Config.Debug then print(('Misión #%s eliminada por %s'):format(id, src)) end
    end
end)