Config = {}

-- 🔑 Tecla para abrir la interfaz de administración de misiones
-- (solo admins tendrán acceso, lo controlaremos en el server.lua)
Config.OpenMenuKey = 'F7'

-- 🎯 Distancia máxima para interactuar con un NPC
Config.InteractDistance = 2.0

-- ⭕ Radio visible del marcador de interacción (cuando es NPC interactivo)
Config.MarkerRadius = 2.5

-- 🎨 Estilo del marker flotante (la "E")
Config.Marker = {
    text = '[E] - Interactuar',
    color = { r = 0, g = 150, b = 255, a = 200 },
    scale = 0.8
}

-- ⚖️ Tiempo de cooldown (ms) después de un robo para evitar spam
Config.RobCooldown = 30000 -- 30 segundos

-- 📀 Animaciones
Config.Animations = {
    rob = { dict = 'random@shop_robbery', anim = 'robbery_action_b' },
    interact = { dict = 'amb@prop_human_parking_meter@male@idle_a', anim = 'idle_a' }
}

-- 👮 Integración con policía
Config.AlertPoliceOnRob = true
Config.AlertPoliceChance = 50 -- % de probabilidad de que avise a la poli en un robo

-- ⚠️ Debug mode (true = prints en consola)
Config.Debug = true
