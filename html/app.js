let missionsListCache = {};
let windowOpen = 'list';

const missionsListRob = document.getElementById('missionsRob');
const missionsListInt = document.getElementById('missionsInteract');
const createForm = document.getElementById('createForm');
const missionType = document.getElementById('missionType');
const tabs = document.querySelectorAll('.tabs button');
const tabviews = document.querySelectorAll('.tabview');

// Tabs
tabs.forEach(tab => {
  tab.addEventListener('click', () => {
    tabs.forEach(t => t.classList.remove('active'));
    tabviews.forEach(v => v.classList.remove('active'));
    tab.classList.add('active');
    document.getElementById(`tab-${tab.dataset.tab}`).classList.add('active');
    windowOpen = tab.dataset.tab;
  });
});

// Selección de NPC
function selectPed(model) {
  const input = document.getElementById('npcModel');
  input.value = model;
  alert(`NPC seleccionado: ${model}`);
}

// Colocar NPC
document.getElementById('placeNpcBtn').addEventListener('click', () => {
  const model = document.getElementById('npcModel').value;
  if (!model) {
    alert("Primero selecciona un modelo de NPC");
    return;
  }
  postNUI('startPlacement', { model });
});

// Cambiar tipo de misión
missionType.addEventListener('change', e => {
  renderConfigFields(e.target.value);
});

// Renderizar campos dinámicos
function renderConfigFields(type) {
  const fields = document.getElementById('configFields');
  fields.innerHTML = '';

  if (type === 'robable') {
    fields.innerHTML = `
      <h4>Loot configurado</h4>
      <div id="lootInputs" class="inline-inputs">
        <input type="text" id="lootItem" placeholder="Item">
        <input type="number" id="lootCount" placeholder="Cantidad" min="1">
        <input type="number" id="lootChance" placeholder="Probabilidad %" min="0" max="100">
        <button type="button" id="addLootBtn">+</button>
      </div>
      <table id="lootTable" class="config-table">
        <thead><tr><th>Item</th><th>Cantidad</th><th>Probabilidad</th></tr></thead>
        <tbody></tbody>
      </table>

      <h4>Armas permitidas</h4>
      <div class="checkboxes">
        <label><input type="checkbox" id="weaponMelee"> Arma blanca</label>
        <label><input type="checkbox" id="weaponPistol"> Pistolas</label>
        <label><input type="checkbox" id="weaponSMG"> Armas cortas (SMG/Escopetas)</label>
        <label><input type="checkbox" id="weaponRifle"> Armas largas (Rifles/Snipers)</label>
      </div>
    `;

    const loot = [];
    document.getElementById('addLootBtn').addEventListener('click', () => {
      const item = document.getElementById('lootItem').value;
      const count = parseInt(document.getElementById('lootCount').value);
      const chance = parseInt(document.getElementById('lootChance').value);

      if (!item || !count || chance == null) {
        alert("Completa todos los campos");
        return;
      }

      loot.push({ item, count, chance });
      const row = `<tr><td>${item}</td><td>${count}</td><td>${chance}%</td></tr>`;
      document.querySelector('#lootTable tbody').insertAdjacentHTML('beforeend', row);

      document.getElementById('lootItem').value = '';
      document.getElementById('lootCount').value = '';
      document.getElementById('lootChance').value = '';
    });

    window.currentLoot = loot;

  } else if (type === 'interactivo') {
    fields.innerHTML = `
      <h4>Requiere</h4>
      <div id="requireInputs" class="inline-inputs">
        <input type="text" id="requireItem" placeholder="Item">
        <input type="number" id="requireCount" placeholder="Cantidad" min="1">
        <button type="button" id="addRequireBtn">+</button>
      </div>
      <table id="requireTable" class="config-table">
        <thead><tr><th>Item</th><th>Cantidad</th></tr></thead>
        <tbody></tbody>
      </table>

      <h4>Recompensa</h4>
      <div id="rewardInputs" class="inline-inputs">
        <input type="text" id="rewardItem" placeholder="Item">
        <input type="number" id="rewardCount" placeholder="Cantidad" min="1">
        <button type="button" id="addRewardBtn">+</button>
      </div>
      <table id="rewardTable" class="config-table">
        <thead><tr><th>Item</th><th>Cantidad</th></tr></thead>
        <tbody></tbody>
      </table>
    `;

    const require = [];
    const reward = [];

    document.getElementById('addRequireBtn').addEventListener('click', () => {
      const item = document.getElementById('requireItem').value;
      const count = parseInt(document.getElementById('requireCount').value);
      if (!item || !count) return;

      require.push({ item, count });
      const row = `<tr><td>${item}</td><td>${count}</td></tr>`;
      document.querySelector('#requireTable tbody').insertAdjacentHTML('beforeend', row);

      document.getElementById('requireItem').value = '';
      document.getElementById('requireCount').value = '';
    });

    document.getElementById('addRewardBtn').addEventListener('click', () => {
      const item = document.getElementById('rewardItem').value;
      const count = parseInt(document.getElementById('rewardCount').value);
      if (!item || !count) return;

      reward.push({ item, count });
      const row = `<tr><td>${item}</td><td>${count}</td></tr>`;
      document.querySelector('#rewardTable tbody').insertAdjacentHTML('beforeend', row);

      document.getElementById('rewardItem').value = '';
      document.getElementById('rewardCount').value = '';
    });

    window.currentRequire = require;
    window.currentReward = reward;
  }
}

// Guardar misión
createForm.addEventListener('submit', e => {
  e.preventDefault();

  const name = document.getElementById('missionName').value;
  const npcModel = document.getElementById('npcModel').value || 'a_m_m_business_01';
  const type = missionType.value;
  let config = {};

  if (type === 'robable') {
    config.loot = window.currentLoot || [];
    config.weapons = {
      melee: document.getElementById('weaponMelee').checked,
      pistol: document.getElementById('weaponPistol').checked,
      smg: document.getElementById('weaponSMG').checked,
      rifle: document.getElementById('weaponRifle').checked
    };
  } else {
    config.require = window.currentRequire || [];
    config.reward = window.currentReward || [];
  }

  const x = parseFloat(document.getElementById('npcX').value) || 0.0;
  const y = parseFloat(document.getElementById('npcY').value) || 0.0;
  const z = parseFloat(document.getElementById('npcZ').value) || 0.0;
  const w = parseFloat(document.getElementById('npcHeading').value) || 0.0;

  if (!confirm(`¿Quieres ${window.editingMissionId ? 'actualizar' : 'guardar'} la misión "${name}"?`)) return;

  if (window.editingMissionId) {
    postNUI('updateMission', {
      id: window.editingMissionId,
      name, npc_model: npcModel, type, config,
      coords: { x, y, z, w }
    });
    window.editingMissionId = null;
  } else {
    postNUI('createMission', {
      name, npc_model: npcModel, type, config,
      coords: { x, y, z, w }
    });
  }
});

// Render misiones
function renderMissions(list) {
  missionsListRob.innerHTML = '';
  missionsListInt.innerHTML = '';
  missionsListCache = list || {};

  if (!list || Object.keys(list).length === 0) {
    missionsListRob.innerHTML = '<p>No hay robos registrados.</p>';
    missionsListInt.innerHTML = '<p>No hay interacciones registradas.</p>';
    return;
  }

  for (const id in list) {
    const m = list[id];
    const card = document.createElement('div');
    card.className = 'card';
    card.innerHTML = `
      <h4>${m.name}</h4>
      <small>Tipo: ${m.type} · Modelo: ${m.npc_model}</small><br>
      <small>Coords: ${parseFloat(m.x).toFixed(2)}, ${parseFloat(m.y).toFixed(2)}, ${parseFloat(m.z).toFixed(2)}</small><br>
      <button class="btn ghost" onclick="editMission(${id})">Editar</button>
      <button class="btn ghost danger" onclick="deleteMission(${id})">Eliminar</button>
    `;
    if (m.type === 'robable') missionsListRob.appendChild(card);
    else missionsListInt.appendChild(card);
  }
}

// Editar misión
function editMission(id) {
  const m = missionsListCache[id];
  if (!m) {
    alert("Misión no encontrada");
    return;
  }

  window.editingMissionId = id;
  document.getElementById('missionName').value = m.name;
  document.getElementById('npcModel').value = m.npc_model;
  missionType.value = m.type;
  renderConfigFields(m.type);

  try {
    const cfg = typeof m.config === 'string' ? JSON.parse(m.config) : m.config;
    if (m.type === 'robable' && cfg.loot) {
      window.currentLoot = cfg.loot;
      cfg.loot.forEach(l => {
        const row = `<tr><td>${l.item}</td><td>${l.count}</td><td>${l.chance}%</td></tr>`;
        document.querySelector('#lootTable tbody').insertAdjacentHTML('beforeend', row);
      });
      if (cfg.weapons) {
        document.getElementById('weaponMelee').checked = cfg.weapons.melee;
        document.getElementById('weaponPistol').checked = cfg.weapons.pistol;
        document.getElementById('weaponSMG').checked = cfg.weapons.smg;
        document.getElementById('weaponRifle').checked = cfg.weapons.rifle;
      }
    } else if (m.type === 'interactivo') {
      window.currentRequire = cfg.require || [];
      window.currentReward = cfg.reward || [];
      window.currentRequire.forEach(r => {
        const row = `<tr><td>${r.item}</td><td>${r.count}</td></tr>`;
        document.querySelector('#requireTable tbody').insertAdjacentHTML('beforeend', row);
      });
      window.currentReward.forEach(r => {
        const row = `<tr><td>${r.item}</td><td>${r.count}</td></tr>`;
        document.querySelector('#rewardTable tbody').insertAdjacentHTML('beforeend', row);
      });
    }
  } catch {}

  document.getElementById('npcX').value = m.x;
  document.getElementById('npcY').value = m.y;
  document.getElementById('npcZ').value = m.z;
  document.getElementById('npcHeading').value = m.heading;

  tabs.forEach(t => t.classList.remove('active'));
  tabviews.forEach(v => v.classList.remove('active'));
  document.querySelector('[data-tab="create"]').classList.add('active');
  document.getElementById('tab-create').classList.add('active');
}

// Eliminar misión
function deleteMission(id) {
  if (!confirm("¿Seguro que quieres eliminar esta misión?")) return;
  postNUI('deleteMission', { id });
}

// PostNUI helper
function postNUI(action, payload) {
  fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload)
  });
}

// Listener de mensajes
window.addEventListener('message', (e) => {
  const { action, payload } = e.data || {};
  if (action === 'missions') renderMissions(payload);
  if (action === 'npcCoords' && payload) {
    document.getElementById('npcX').value = payload.x;
    document.getElementById('npcY').value = payload.y;
    document.getElementById('npcZ').value = payload.z;
    document.getElementById('npcHeading').value = payload.w;
    alert(`NPC colocado en: ${payload.x.toFixed(2)}, ${payload.y.toFixed(2)}, ${payload.z.toFixed(2)} (H:${payload.w.toFixed(1)})`);
  }
  if (action === 'hideUI' || action === 'close') {
    document.body.style.display = "none";
    // Reset form
    document.getElementById('missionName').value = '';
    document.getElementById('npcModel').value = '';
    document.getElementById('npcX').value = '';
    document.getElementById('npcY').value = '';
    document.getElementById('npcZ').value = '';
    document.getElementById('npcHeading').value = '';
    document.getElementById('configFields').innerHTML = '';
    window.currentLoot = [];
    window.currentRequire = [];
    window.currentReward = [];
    window.editingMissionId = null;
  }
  if (action === 'showUI' || action === 'open') {
    document.body.style.display = "block";
  }
});

// Cerrar menú con ESC
document.addEventListener('keydown', (e) => {
  if (e.key === "Escape") {
    postNUI('close', {});
  }
});
