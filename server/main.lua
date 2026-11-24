local Proxy = module("vrp","lib/Proxy")
local vRP = Proxy and Proxy.getInterface("vRP")

local textos = Config.textos

local function ehAdmin(src)
	src = tonumber(src)
	if not src or src == 0 then return true end

	if framezero and framezero.HasPermission then
		for _, perm in ipairs(Config.permissoesBridge or { 'admin', 'Admin' }) do
			local ok, res = pcall(framezero.HasPermission, src, perm)
			if ok and res then return true end
		end
	end

	if vRP and vRP.getUserId then
		local userId = vRP.getUserId(src)
		if userId and vRP.hasPermission(userId, Config.permissao) then
			return true
		end
	end

	if IsPlayerAceAllowed(src, 'piercer.admin') or IsPlayerAceAllowed(src, 'command.clothslot') then
		return true
	end

	return false
end

local function modeloValido(modelo)
	for _, nome in ipairs(Config.modelos) do
		if modelo == nome then return true end
	end
	return false
end

local function contarPorColecao(texto)
	local contagem = {}
	if not texto then return contagem end

	local primeiraLinha = true
	for linha in texto:gmatch('[^\r\n]+') do
		if primeiraLinha then
			primeiraLinha = false
		else
			local _, colecao = linha:match('^([^;]*);([^;]*);')
			if colecao and colecao ~= '' then
				contagem[colecao] = (contagem[colecao] or 0) + 1
			end
		end
	end
	return contagem
end

local function listarMudancas(antigo, novo)
	local mudancas = {}
	for colecao, quantidade in pairs(novo) do
		if not antigo[colecao] then
			mudancas[#mudancas + 1] = ('+%s (%d)'):format(colecao, quantidade)
		elseif antigo[colecao] ~= quantidade then
			mudancas[#mudancas + 1] = ('%s %d->%d'):format(colecao, antigo[colecao], quantidade)
		end
	end

	for colecao, quantidade in pairs(antigo) do
		if not novo[colecao] then
			mudancas[#mudancas + 1] = ('-%s (%d)'):format(colecao, quantidade)
		end
	end

	table.sort(mudancas)
	return mudancas
end

local indice = { caminhos = {}, duvidosos = {} }

local function carregarIndice()
	local conteudo = LoadResourceFile(GetCurrentResourceName(), 'data/index.lua')
	if not conteudo then
		conteudo = LoadResourceFile(GetCurrentResourceName(), 'index.lua')
	end
	local funcao = conteudo and load(conteudo)
	local lido = funcao and funcao() or {}
	indice = { caminhos = lido.caminhos or {}, duvidosos = lido.duvidosos or {} }
end

AddEventHandler('onResourceStart', function(recurso)
	if recurso == GetCurrentResourceName() then
		carregarIndice()
	end
end)

local function obterCaminhos(modelo, itens)
	local caminhos = {}
	if not modeloValido(modelo) or type(itens) ~= 'table' then return caminhos end

	for _, item in ipairs(itens) do
		if type(item) == 'table' and type(item[1]) == 'string' and type(item[2]) == 'string' and type(item[3]) == 'number' then
			local chave = ('%s|%s|%s|%d'):format(modelo, item[1], item[2], item[3])
			local grupo = ('%s|%s|%s'):format(modelo, item[1], item[2])
			local caminho = indice.caminhos[chave]
			if caminho and indice.duvidosos[grupo] then
				caminho = caminho .. textos.painelDuvidoso
			end
			caminhos[('%s|%s|%d'):format(item[1], item[2], item[3])] = caminho
		end
	end
	return caminhos
end

RegisterNetEvent('style_roupaslot:caminhos', function(modelo, itens)
	local src = source
	if not ehAdmin(src) then return end
	local caminhos = obterCaminhos(modelo, itens)
	TriggerClientEvent('style_roupaslot:caminhos', src, caminhos)
end)
RegisterNetEvent('piercer_clothslot:caminhos', function(modelo, itens)
	local src = source
	if not ehAdmin(src) then return end
	local caminhos = obterCaminhos(modelo, itens)
	TriggerClientEvent('piercer_clothslot:caminhos', src, caminhos)
end)

local function executarBusca(modelo, texto)
	local procurado = texto:lower()
	local prefixo = modelo .. '|'
	local achados = {}
	for chave, caminho in pairs(indice.caminhos) do
		if chave:sub(1, #prefixo) == prefixo and caminho:lower():find(procurado, 1, true) then
			local _, colecao, peca, numero = chave:match('^([^|]+)|([^|]+)|([^|]+)|(%d+)$')
			achados[#achados + 1] = {
				collection = colecao,
				piece = peca,
				number = tonumber(numero),
				folder = caminho
			}
		end
	end

	table.sort(achados, function(a, b)
		if a.collection ~= b.collection then return a.collection < b.collection end
		if a.piece ~= b.piece then return a.piece < b.piece end
		return a.number < b.number
	end)

	local mostrados = {}
	for i = 1, math.min(#achados, 60) do
		mostrados[i] = achados[i]
	end
	return #achados, mostrados
end

RegisterNetEvent('style_roupaslot:buscar', function(modelo, texto)
	local src = source
	if not ehAdmin(src) then return end
	if not modeloValido(modelo) or type(texto) ~= 'string' or #texto < 2 then return end

	local total, achados = executarBusca(modelo, texto)
	local legacy = {}
	for _, it in ipairs(achados) do
		legacy[#legacy + 1] = { it.collection, it.piece, it.number, it.folder }
	end
	TriggerClientEvent('style_roupaslot:resultadoBusca', src, texto, total, legacy)
end)

RegisterNetEvent('piercer_clothslot:searchNui', function(modelo, texto, queryId)
	local src = source
	if not ehAdmin(src) then return end
	if not modeloValido(modelo) or type(texto) ~= 'string' then return end

	local total, achados = executarBusca(modelo, texto)
	TriggerClientEvent('piercer_clothslot:searchResult', src, queryId, achados)
end)

local function salvarDump(src, modelo, texto)
	local recurso = GetCurrentResourceName()
	local arquivo = 'data/dump_' .. modelo .. '.txt'

	local antigo = contarPorColecao(LoadResourceFile(recurso, arquivo))
	local novo = contarPorColecao(texto)
	local mudancas = listarMudancas(antigo, novo)

	SaveResourceFile(recurso, arquivo, texto, -1)

	local mensagem = textos.dumpSalvo:format(arquivo) .. ' '
	if #mudancas == 0 then
		mensagem = mensagem .. textos.dumpSemMudanca
	else
		mensagem = mensagem .. textos.dumpMudancas:format(table.concat(mudancas, ', '))
	end

	print('[piercer_clothslot] ' .. mensagem)
	if framezero and framezero.Notify then
		framezero.Notify(src, 'success', mensagem, 8000)
	else
		TriggerClientEvent('Notify', src, 'sucesso', mensagem, 8000)
	end
end

RegisterNetEvent('style_roupaslot:save', function(modelo, texto)
	local src = source
	if not ehAdmin(src) then return end
	salvarDump(src, modelo, texto)
end)
RegisterNetEvent('piercer_clothslot:save', function(modelo, texto)
	local src = source
	if not ehAdmin(src) then return end
	salvarDump(src, modelo, texto)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- COMANDOS
-----------------------------------------------------------------------------------------------------------------------------------------
local comandos = Config.comandos or { 'clothslot', 'roupaslot' }

for _, cmd in ipairs(comandos) do
	RegisterCommand(cmd, function(src, args)
		if ehAdmin(src) then
			-- Se digitar sem argumentos, abre a interface NUI moderna
			if not args or #args == 0 then
				TriggerClientEvent('piercer_clothslot:openUI', src)
			else
				-- Se passar argumentos (ex: /clothslot vestir, /clothslot painel), roda ação direta
				TriggerClientEvent('piercer_clothslot:run', src, args)
				TriggerClientEvent('style_roupaslot:run', src, args)
			end
		else
			if framezero and framezero.Notify then
				framezero.Notify(src, 'error', 'Você não tem permissão para usar este comando.', 5000)
			else
				TriggerClientEvent('Notify', src, 'negado', 'Sem permissão.', 5000)
			end
		end
	end, false)
end
