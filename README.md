# 🚀 F4R3 Missions

Script personalizado para servidores **FiveM** basado en **Qbox**, que permite crear, gestionar y completar misiones dentro del juego de forma dinámica.

---

## 📌 Características
- 🎯 Sistema de misiones dinámico
- 🛠️ Compatible con **Qbox**
- 👥 Posibilidad de configurar misiones individuales o en grupo
- ⚡ Optimizado para servidores RP
- 🔧 Fácil configuración y personalización

---

## 📂 Instalación
1. Descarga o clona este repositorio en tu carpeta de recursos de FiveM:
   ```bash
   git clone https://github.com/F4R3Juan58/F4R3-Missions.git
   ```
2. Asegúrate de tener **Qbox Framework** instalado.
3. Añade `ensure F4R3-Missions` en tu `server.cfg`.

---

## ⚙️ Configuración
- Edita el archivo de configuración (`config.lua`) para personalizar:
  - Recompensas
  - Ubicaciones
  - Objetivos
  - Niveles de dificultad

---

## 🗄️ Base de datos

El proyecto incluye un fichero [`F4R3-Missions.sql`](./F4R3-Missions.sql) que crea la tabla necesaria para gestionar las misiones en la base de datos.

```sql
CREATE TABLE IF NOT EXISTS `missions` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `npc_model` VARCHAR(60) NOT NULL DEFAULT 'a_m_m_business_01',
  `type` ENUM('robable','interactivo') NOT NULL,
  `config` JSON DEFAULT NULL, -- loot, requisitos, recompensas, armas permitidas
  `x` FLOAT NOT NULL,
  `y` FLOAT NOT NULL,
  `z` FLOAT NOT NULL,
  `heading` FLOAT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

📌 Esta tabla almacena:
- `name`: Nombre de la misión.
- `npc_model`: Modelo de NPC asociado.
- `type`: Tipo de misión (`robable` o `interactivo`).
- `config`: JSON con loot, requisitos, recompensas o armas.
- `x, y, z, heading`: Coordenadas y orientación del NPC/misión.
- `created_at`: Fecha de creación.

Para importar la tabla:
```bash
mysql -u usuario -p basededatos < F4R3-Missions.sql
```

---

## 🖼️ Capturas de pantalla
_(Aquí puedes añadir imágenes del script en acción dentro del juego)_

---

## 📜 Requisitos
- [Qbox Framework](https://github.com/Qbox-framework)
- Servidor **FiveM** actualizado

---

## 👨‍💻 Autor
Desarrollado por **Juan Gabriel Gallardo Martín**  
🔗 [GitHub](https://github.com/F4R3Juan58) | [LinkedIn](https://linkedin.com/in/tuperfil)

---
