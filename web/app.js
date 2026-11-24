const I18N = {
    pt: {
        subtitle: 'Inspetor de Slots e Pastas de Roupas',
        btnRefresh: 'Atualizar',
        btnDump: 'Gerar Dump',
        statEquipped: 'Peças no Corpo',
        statEquippedSub: 'Componentes vestidos',
        statAddons: 'Packs / Addons',
        statAddonsSub: 'Coleções carregadas',
        statModel: 'Modelo do Ped',
        statModelSub: 'Personagem atual',
        statSlots: 'Total de Slots',
        statSlotsSub: 'Indexados na base',
        tabEquipped: 'No Corpo / Equipadas',
        tabSearch: 'Buscar Roupas',
        tabCollections: 'Coleções Carregadas',
        allCategories: 'Todas as Peças',
        searchPlaceholder: 'Buscar por pasta (ex: nike, bagdad, jaqueta)...',
        statusReady: 'Pronto',
        statusHint: 'Pressione PageDown / PageUp para navegar nas roupas',
        statusLoading: 'Carregando dados...',
        btnCopyPath: 'Copiar Pasta',
        btnCopySlot: 'Copiar Slot',
        btnWear: 'Vestir',
        copiedToast: 'Copiado para a área de transferência!',
        wearToast: 'Roupa aplicada no personagem!',
        dumpSuccess: 'Dump gerado com sucesso no servidor!',
        baseCloth: 'Roupa base do jogo (sem pasta addon)',
        noFolder: 'Pasta não localizada no índice',
        colHeaderName: 'Coleção / Pack',
        colHeaderPiece: 'Componente',
        colHeaderCount: 'Quantidade',
        colHeaderRange: 'Faixa de Slots'
    },
    en: {
        subtitle: 'Clothing Slots & Folders Inspector',
        btnRefresh: 'Refresh',
        btnDump: 'Generate Dump',
        statEquipped: 'Equipped Items',
        statEquippedSub: 'Components worn',
        statAddons: 'Packs / Addons',
        statAddonsSub: 'Loaded collections',
        statModel: 'Ped Model',
        statModelSub: 'Current ped',
        statSlots: 'Total Slots',
        statSlotsSub: 'Indexed in server',
        tabEquipped: 'Equipped Clothes',
        tabSearch: 'Search Clothes',
        tabCollections: 'Loaded Collections',
        allCategories: 'All Components',
        searchPlaceholder: 'Search by folder (e.g. nike, bagdad, jacket)...',
        statusReady: 'Ready',
        statusHint: 'Press PageDown / PageUp to cycle clothes in game',
        statusLoading: 'Loading data...',
        btnCopyPath: 'Copy Path',
        btnCopySlot: 'Copy Slot',
        btnWear: 'Wear',
        copiedToast: 'Copied to clipboard!',
        wearToast: 'Outfit applied to character!',
        dumpSuccess: 'Full clothing dump generated on server!',
        baseCloth: 'Base GTA V cloth (no addon folder)',
        noFolder: 'Folder not found in index',
        colHeaderName: 'Collection / Pack',
        colHeaderPiece: 'Component',
        colHeaderCount: 'Count',
        colHeaderRange: 'Slot Range'
    }
};

let currentLang = localStorage.getItem('piercer_lang') || 'pt';

const isFiveM = (typeof window.GetParentResourceName === 'function') || 
                (window.invokeNative !== undefined) || 
                (window.location.protocol === 'nui:');

const resourceName = isFiveM ? window.GetParentResourceName() : 'piercer_clothslot';

let state = {
    activeTab: 'equipped',
    equippedItems: [],
    collections: [],
    searchResults: [],
    pedModel: 'mp_m_freemode_01',
    totalSlots: 0,
    searchQuery: '',
    selectedSearchCategory: ''
};

const appEl = document.getElementById('app');
const statEquipped = document.getElementById('stat-equipped');
const statAddons = document.getElementById('stat-addons');
const statModel = document.getElementById('stat-model');
const statSlots = document.getElementById('stat-slots');

const langPtBtn = document.getElementById('lang-pt');
const langEnBtn = document.getElementById('lang-en');

const btnRefresh = document.getElementById('btn-refresh');
const btnDump = document.getElementById('btn-dump');
const btnClose = document.getElementById('btn-close');

const searchControls = document.getElementById('search-controls');
const selectSearchCategory = document.getElementById('select-search-category');
const searchInput = document.getElementById('search-input');

const viewEquipped = document.getElementById('view-equipped');
const viewSearch = document.getElementById('view-search');
const viewCollections = document.getElementById('view-collections');

const equippedList = document.getElementById('equipped-list');
const searchList = document.getElementById('search-list');
const collectionsList = document.getElementById('collections-list');

const loadingState = document.getElementById('loading');
const loadingText = document.getElementById('loading-text');

const toast = document.getElementById('toast');
const toastMessage = document.getElementById('toast-message');

function t(key) {
    return (I18N[currentLang] && I18N[currentLang][key]) || (I18N['pt'][key]) || key;
}

function updateLanguageUI() {
    langPtBtn.classList.toggle('active', currentLang === 'pt');
    langEnBtn.classList.toggle('active', currentLang === 'en');

    document.getElementById('t-subtitle').textContent = t('subtitle');
    document.getElementById('t-btn-refresh').textContent = t('btnRefresh');
    document.getElementById('t-btn-dump').textContent = t('btnDump');

    document.getElementById('t-stat-equipped').textContent = t('statEquipped');
    document.getElementById('t-stat-equipped-sub').textContent = t('statEquippedSub');
    document.getElementById('t-stat-addons').textContent = t('statAddons');
    document.getElementById('t-stat-addons-sub').textContent = t('statAddonsSub');
    document.getElementById('t-stat-model').textContent = t('statModel');
    document.getElementById('t-stat-model-sub').textContent = t('statModelSub');
    document.getElementById('t-stat-slots').textContent = t('statSlots');
    document.getElementById('t-stat-slots-sub').textContent = t('statSlotsSub');

    document.getElementById('t-tab-equipped').textContent = t('tabEquipped');
    document.getElementById('t-tab-search').textContent = t('tabSearch');
    document.getElementById('t-tab-collections').textContent = t('tabCollections');

    searchInput.placeholder = t('searchPlaceholder');
    document.getElementById('t-status-ready').textContent = t('statusReady');
    document.getElementById('status-hint').textContent = t('statusHint');

    if (selectSearchCategory.options.length > 0) {
        selectSearchCategory.options[0].textContent = t('allCategories');
    }

    renderEquipped();
    renderCollections();
}

function setLanguage(lang) {
    currentLang = lang;
    localStorage.setItem('piercer_lang', lang);
    updateLanguageUI();
}

langPtBtn.addEventListener('click', () => setLanguage('pt'));
langEnBtn.addEventListener('click', () => setLanguage('en'));

function showToast(msg, isError = false) {
    toastMessage.textContent = msg;
    toast.style.borderColor = isError ? '#ef4444' : '#8B5CF6';
    toast.classList.remove('hidden');
    clearTimeout(toast._timer);
    toast._timer = setTimeout(() => {
        toast.classList.add('hidden');
    }, 2800);
}

// Fetch equipped & collections data from FiveM client
async function fetchClientData() {
    showLoading(true, t('statusLoading'));
    try {
        if (isFiveM) {
            const res = await fetch(`https://${resourceName}/getEquippedData`, {
                method: 'POST',
                body: '{}'
            });
            const data = await res.json();
            if (data) {
                applyServerData(data);
            }
        } else {
            // Mock preview data for standalone browser testing
            applyServerData({
                model: 'mp_m_freemode_01',
                equippedCount: 8,
                addonsCount: 13,
                totalSlots: 4520,
                equipped: [
                    { componentId: 11, componentName: 'jbib (Jaqueta)', slot: 462, texture: 0, collection: 'mp_m_freemode_01_addon', number: 0, folder: '00 [bagdad-store] c e loko papi' },
                    { componentId: 4, componentName: 'lowr (Calça)', slot: 380, texture: 1, collection: 'mp_m_freemode_01_addon2', number: 14, folder: '14 [Nike] Tech Fleece Black' },
                    { componentId: 6, componentName: 'feet (Sapatos)', slot: 115, texture: 0, collection: 'mp_m_freemode_01_addon', number: 5, folder: '05 [AirJordan] Retro 4' },
                    { componentId: 1, componentName: 'berd (Máscara)', slot: 88, texture: 0, collection: 'base', number: 0, folder: '' },
                    { componentId: 7, componentName: 'teef (Acessórios)', slot: 120, texture: 0, collection: 'mp_m_freemode_01_addon', number: 0, folder: '00 [ajna-mods] judge hammer' },
                    { componentId: 2, componentName: 'hair (Cabelo)', slot: 45, texture: 0, collection: 'base', number: 0, folder: '' }
                ],
                collections: [
                    { name: 'mp_m_freemode_01_addon', totalPieces: 680, slotMin: 100, slotMax: 780 },
                    { name: 'mp_m_freemode_01_addon2', totalPieces: 520, slotMin: 781, slotMax: 1301 },
                    { name: 'mp_m_freemode_01_addon3', totalPieces: 490, slotMin: 1302, slotMax: 1792 }
                ]
            });
        }
    } catch (e) {
        console.error('Falha ao obter dados:', e);
    } finally {
        showLoading(false);
    }
}

function applyServerData(data) {
    state.pedModel = data.model || 'mp_m_freemode_01';
    state.equippedItems = data.equipped || [];
    state.collections = data.collections || [];
    state.totalSlots = data.totalSlots || 0;

    statEquipped.textContent = `${data.equippedCount || state.equippedItems.length} / 12`;
    statAddons.textContent = data.addonsCount || state.collections.length;
    statModel.textContent = state.pedModel.includes('female') || state.pedModel.includes('_f_') ? 'Feminino' : 'Masculino';
    statSlots.textContent = state.totalSlots;

    document.getElementById('status-summary').textContent = `${state.equippedItems.length} peças lidas no corpo`;

    renderEquipped();
    renderCollections();
}

function renderEquipped() {
    equippedList.innerHTML = '';
    if (state.equippedItems.length === 0) {
        equippedList.innerHTML = '<div style="color: #a1a1aa; padding: 20px;">Nenhuma roupa equipada detectada.</div>';
        return;
    }

    for (const item of state.equippedItems) {
        const isAddon = item.collection && item.collection !== '' && item.collection !== 'base';
        const card = document.createElement('div');
        card.className = `cloth-card ${isAddon ? 'is-addon' : 'is-base'}`;

        const folderText = isAddon ? (item.folder || t('noFolder')) : t('baseCloth');

        card.innerHTML = `
            <div class="cloth-card-header">
                <span class="cloth-component-title">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect></svg>
                    ${escapeHtml(item.componentName)}
                </span>
                <span class="cloth-slot-badge">Slot ${item.slot} (Tex ${item.texture})</span>
            </div>
            <div class="cloth-card-body">
                <div class="cloth-origin-name">
                    ${isAddon ? `${escapeHtml(item.collection)}_${item.number}` : 'GTA V Base'}
                </div>
                <div class="cloth-folder-path">
                    📁 ${escapeHtml(folderText)}
                </div>
            </div>
            <div class="cloth-card-actions">
                ${isAddon && item.folder ? `
                    <button class="btn btn-secondary btn-copy-path" data-path="${escapeHtml(item.folder)}">
                        ${t('btnCopyPath')}
                    </button>
                ` : ''}
                <button class="btn btn-secondary btn-copy-slot" data-slot="${item.slot}">
                    ${t('btnCopySlot')}
                </button>
            </div>
        `;

        const btnCopyPath = card.querySelector('.btn-copy-path');
        if (btnCopyPath) {
            btnCopyPath.addEventListener('click', () => {
                navigator.clipboard.writeText(btnCopyPath.getAttribute('data-path'));
                showToast(t('copiedToast'));
            });
        }

        const btnCopySlot = card.querySelector('.btn-copy-slot');
        if (btnCopySlot) {
            btnCopySlot.addEventListener('click', () => {
                navigator.clipboard.writeText(btnCopySlot.getAttribute('data-slot'));
                showToast(t('copiedToast'));
            });
        }

        equippedList.appendChild(card);
    }
}

function renderCollections() {
    collectionsList.innerHTML = '';
    if (state.collections.length === 0) return;

    let html = `
        <table class="col-table">
            <thead>
                <tr>
                    <th>${t('colHeaderName')}</th>
                    <th>${t('colHeaderCount')}</th>
                    <th>${t('colHeaderRange')}</th>
                </tr>
            </thead>
            <tbody>
    `;

    for (const c of state.collections) {
        html += `
            <tr>
                <td style="font-family: monospace; font-weight: 700; color: #a78bfa;">${escapeHtml(c.name)}</td>
                <td>${c.totalPieces} itens</td>
                <td style="font-family: monospace; color: #f59e0b;">Slots ${c.slotMin} a ${c.slotMax}</td>
            </tr>
        `;
    }

    html += `</tbody></table>`;
    collectionsList.innerHTML = html;
}

// Search feature
async function executeSearch() {
    const q = searchInput.value.trim();
    if (q.length < 2) return;

    showLoading(true, 'Buscando...');
    try {
        if (isFiveM) {
            const res = await fetch(`https://${resourceName}/searchClothes`, {
                method: 'POST',
                body: JSON.stringify({
                    query: q,
                    category: selectSearchCategory.value
                })
            });
            const data = await res.json();
            renderSearchResults(data || []);
        }
    } catch (e) {
        console.error('Falha na busca:', e);
    } finally {
        showLoading(false);
    }
}

function renderSearchResults(items) {
    searchList.innerHTML = '';
    if (items.length === 0) {
        searchList.innerHTML = '<div style="color: #a1a1aa; padding: 20px;">Nenhuma roupa encontrada para este termo.</div>';
        return;
    }

    for (const item of items) {
        const card = document.createElement('div');
        card.className = 'cloth-card is-addon';
        card.innerHTML = `
            <div class="cloth-card-header">
                <span class="cloth-component-title">${escapeHtml(item.pieceName || item.piece)}</span>
                <span class="cloth-slot-badge">Slot ${item.slot}</span>
            </div>
            <div class="cloth-card-body">
                <div class="cloth-origin-name">${escapeHtml(item.collection)}_${item.number}</div>
                <div class="cloth-folder-path">📁 ${escapeHtml(item.folder)}</div>
            </div>
            <div class="cloth-card-actions">
                <button class="btn btn-primary btn-wear" data-col="${escapeHtml(item.collection)}" data-piece="${item.pieceId}" data-num="${item.number}">
                    ${t('btnWear')}
                </button>
                <button class="btn btn-secondary btn-copy-slot" data-slot="${item.slot}">
                    ${t('btnCopySlot')}
                </button>
            </div>
        `;

        card.querySelector('.btn-wear').addEventListener('click', e => {
            const btn = e.currentTarget;
            wearItem(btn.getAttribute('data-col'), parseInt(btn.getAttribute('data-piece')), parseInt(btn.getAttribute('data-num')));
        });

        card.querySelector('.btn-copy-slot').addEventListener('click', e => {
            navigator.clipboard.writeText(e.currentTarget.getAttribute('data-slot'));
            showToast(t('copiedToast'));
        });

        searchList.appendChild(card);
    }
}

function wearItem(collection, pieceId, number) {
    if (isFiveM) {
        fetch(`https://${resourceName}/wear`, {
            method: 'POST',
            body: JSON.stringify({ collection, pieceId, number })
        });
        showToast(t('wearToast'));
        setTimeout(fetchClientData, 400);
    }
}

// Dump
async function generateDump() {
    if (isFiveM) {
        showLoading(true, 'Gerando dump no servidor...');
        await fetch(`https://${resourceName}/generateDump`, { method: 'POST', body: '{}' });
        showLoading(false);
        showToast(t('dumpSuccess'));
    }
}

function closeApp() {
    appEl.style.display = 'none';
    if (isFiveM) {
        fetch(`https://${resourceName}/close`, { method: 'POST', body: '{}' });
    }
}

function showLoading(show, text = 'Carregando...') {
    if (show) {
        loadingText.textContent = text;
        loadingState.classList.remove('hidden');
    } else {
        loadingState.classList.add('hidden');
    }
}

function escapeHtml(str) {
    if (!str) return '';
    return String(str).replace(/[&<>"']/g, m => ({
        '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    }[m]));
}

// Tab navigation
document.querySelectorAll('.filter-tabs .tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.filter-tabs .tab-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        state.activeTab = btn.getAttribute('data-tab');

        viewEquipped.classList.toggle('hidden', state.activeTab !== 'equipped');
        viewSearch.classList.toggle('hidden', state.activeTab !== 'search');
        viewCollections.classList.toggle('hidden', state.activeTab !== 'collections');
        searchControls.classList.toggle('hidden', state.activeTab !== 'search');
    });
});

searchInput.addEventListener('keydown', e => {
    if (e.key === 'Enter') {
        executeSearch();
    }
});

btnRefresh.addEventListener('click', fetchClientData);
btnDump.addEventListener('click', generateDump);
btnClose.addEventListener('click', closeApp);

window.addEventListener('keydown', e => {
    if (e.key === 'Escape') closeApp();
});

// FiveM Message Listener
window.addEventListener('message', event => {
    const item = event.data;
    if (item && item.action === 'open') {
        appEl.style.display = 'flex';
        updateLanguageUI();
        if (item.data) {
            applyServerData(item.data);
        } else {
            fetchClientData();
        }
    } else if (item && item.action === 'close') {
        appEl.style.display = 'none';
    } else if (item && item.action === 'update') {
        if (item.data) applyServerData(item.data);
    }
});

// Standalone test
if (!isFiveM) {
    appEl.style.display = 'flex';
    document.addEventListener('DOMContentLoaded', () => {
        updateLanguageUI();
        fetchClientData();
    });
}
