local textos = Config.textos
local nomes = Config.componentes

local numeroDaPeca = {}
for numero, nome in pairs(nomes) do
	numeroDaPeca[nome] = numero
end

local function avisar(tipo, mensagem)
	TriggerEvent('Notify', tipo, mensagem, Config.tempoNotificacao)
	print('^3[roupaslot]^7 ' .. mensagem)
end

local function pedFreemode()
	local ped = PlayerPedId()
	local modelo = GetEntityModel(ped)
	for _, nome in ipairs(Config.modelos) do
		if modelo == GetHashKey(nome) then
			return ped, nome
		end
	end
end

local function descobrirPeca(valor)
	if not valor then return end
	valor = tostring(valor):lower()
	if numeroDaPeca[valor] then
		return numeroDaPeca[valor]
	end
	local numero = tonumber(valor)
	if numero and nomes[math.floor(numero)] then
		return math.floor(numero)
	end
end

local function acharColecao(ped, procurada)
	procurada = procurada:lower()
	for i = 0, GetPedCollectionsCount(ped) - 1 do
		local nome = GetPedCollectionName(ped, i) or ''
		if nome:lower() == procurada then
			return nome
		end
	end
end

local function acharOrigem(ped, peca, slot)
	for i = 0, GetPedCollectionsCount(ped) - 1 do
		local colecao = GetPedCollectionName(ped, i) or ''
		local total = GetNumberOfPedCollectionDrawableVariations(ped, peca, colecao)
		for numero = 0, total - 1 do
			if GetPedDrawableGlobalIndexFromCollection(ped, peca, colecao, numero) == slot then
				return colecao, numero
			end
		end
	end
end

local function gerarDump(ped, modelo)
	local linhas = { 'comp;colecao;local;global;texturas' }

	for i = 0, GetPedCollectionsCount(ped) - 1 do
		local colecao = GetPedCollectionName(ped, i) or ''
		for peca = 0, 11 do
			local total = GetNumberOfPedCollectionDrawableVariations(ped, peca, colecao)
			for numero = 0, total - 1 do
				local slot = GetPedDrawableGlobalIndexFromCollection(ped, peca, colecao, numero)
				local texturas = GetNumberOfPedCollectionTextureVariations(ped, peca, colecao, numero)
				linhas[#linhas + 1] = ('%s;%s;%d;%d;%d'):format(nomes[peca], colecao, numero, slot, texturas)
			end
		end
	end

	TriggerLatentServerEvent('style_roupaslot:save', Config.velocidadeEnvio, modelo, table.concat(linhas, '\n'))
	avisar('aviso', textos.dumpEnviando:format(#linhas - 1))
end

local function consultarSlot(ped, args)
	local peca = descobrirPeca(args[2])
	local numero = tonumber(args[3])
	if not peca or not numero then
		return avisar('negado', textos.usoConsulta)
	end

	local colecao = acharColecao(ped, args[1])
	if not colecao then
		return avisar('negado', textos.colecaoNaoExiste:format(args[1]))
	end

	local total = GetNumberOfPedCollectionDrawableVariations(ped, peca, colecao)
	if numero < 0 or numero >= total then
		return avisar('negado', textos.numeroNaoExiste:format(colecao, total, nomes[peca], total - 1, numero))
	end

	local slot = GetPedDrawableGlobalIndexFromCollection(ped, peca, colecao, numero)
	local texturas = GetNumberOfPedCollectionTextureVariations(ped, peca, colecao, numero)
	avisar('sucesso', textos.achouSlot:format(colecao, nomes[peca], numero, slot, texturas))
end

local function consultarOrigem(ped, args)
	local peca = descobrirPeca(args[2])
	local slot = tonumber(args[3])
	if not peca or not slot then
		return avisar('negado', textos.usoReverso)
	end

	slot = math.floor(slot)
	local colecao, numero = acharOrigem(ped, peca, slot)
	if not colecao then
		return avisar('negado', textos.slotNaoExiste:format(slot, nomes[peca]))
	end

	local origem = colecao == '' and textos.roupaBase or colecao
	avisar('sucesso', textos.achouOrigem:format(slot, nomes[peca], origem, numero))
end

local function mostrarRoupaAtual(ped)
	local linhas = {}
	for peca = 0, 11 do
		local slot = GetPedDrawableVariation(ped, peca)
		local textura = GetPedTextureVariation(ped, peca)
		local colecao, numero = acharOrigem(ped, peca, slot)

		local origem = 'base'
		if colecao and colecao ~= '' then
			origem = ('%s_%s_%03d'):format(colecao, nomes[peca], numero)
		end
		linhas[#linhas + 1] = ('%s: slot %d, textura %d (%s)'):format(nomes[peca], slot, textura, origem)
	end

	print('^3[roupaslot] Vestindo agora:^7\n' .. table.concat(linhas, '\n'))
	avisar('aviso', textos.vejaConsole)
end

local function mostrarColecoes(ped)
	local linhas = { 'colecao | peca | quantidade | slots do jogo' }
	local quantidade = GetPedCollectionsCount(ped)

	for i = 0, quantidade - 1 do
		local colecao = GetPedCollectionName(ped, i) or ''
		for peca = 0, 11 do
			local total = GetNumberOfPedCollectionDrawableVariations(ped, peca, colecao)
			if total > 0 then
				local primeiro = GetPedDrawableGlobalIndexFromCollection(ped, peca, colecao, 0)
				local ultimo = GetPedDrawableGlobalIndexFromCollection(ped, peca, colecao, total - 1)
				local nome = colecao == '' and '(base)' or colecao
				linhas[#linhas + 1] = ('%s | %s | %d | %d a %d'):format(nome, nomes[peca], total, primeiro, ultimo)
			end
		end
	end

	print('^3[roupaslot] Coleções carregadas:^7\n' .. table.concat(linhas, '\n'))
	avisar('aviso', textos.colecoesCarregadas:format(quantidade))
end

local painelLigado = false
local painelModelo = nil
local painelPecas = {}      -- o que está vestido: { peca, slot, textura, colecao, numero }
local painelCaminhos = {}   -- respostas do servidor: "colecao|peca|numero" -> pasta
local painelAssinatura = ''

local function escreverTexto(texto, x, y, escala, r, g, b)
	SetTextFont(0)
	SetTextScale(escala, escala)
	SetTextColour(r, g, b, 255)
	SetTextOutline()
	SetTextEntry('STRING')
	AddTextComponentString(texto)
	DrawText(x, y)
end

local function atualizarPainel(ped, modelo)
	local partes = {}
	for peca = 0, 11 do
		partes[#partes + 1] = GetPedDrawableVariation(ped, peca) .. ':' .. GetPedTextureVariation(ped, peca)
	end
	local assinatura = modelo .. table.concat(partes, ',')
	if assinatura == painelAssinatura then return end
	painelAssinatura = assinatura
	painelModelo = modelo

	local pecas, pedidos = {}, {}
	for peca = 0, 11 do
		local slot = GetPedDrawableVariation(ped, peca)
		local colecao, numero = acharOrigem(ped, peca, slot)
		pecas[#pecas + 1] = {
			peca = peca,
			slot = slot,
			textura = GetPedTextureVariation(ped, peca),
			colecao = colecao,
			numero = numero,
		}
		if colecao and colecao ~= '' then
			pedidos[#pedidos + 1] = { colecao, nomes[peca], numero }
		end
	end
	painelPecas = pecas
	painelCaminhos = {}
	TriggerServerEvent('style_roupaslot:caminhos', modelo, pedidos)
end

RegisterNetEvent('style_roupaslot:caminhos', function(caminhos)
	painelCaminhos = caminhos or {}
end)

local function desenharPainel()
	local cfg = Config.painel
	local linhas = {}
	for _, item in ipairs(painelPecas) do
		if item.colecao and item.colecao ~= '' then
			local nome = nomes[item.peca]
			local chave = ('%s|%s|%d'):format(item.colecao, nome, item.numero)
			linhas[#linhas + 1] = {
				cabecalho = ('%s_%s_%03d   slot %d   textura %d'):format(item.colecao, nome, item.numero, item.slot, item.textura),
				pasta = painelCaminhos[chave] or textos.painelSemPasta,
			}
		end
	end

	local altura = 0.034 + (#linhas > 0 and #linhas * 0.052 or 0.026)
	DrawRect(cfg.x + cfg.largura / 2, cfg.y + altura / 2 - 0.004, cfg.largura, altura, 12, 14, 20, 190)
	escreverTexto(textos.painelTitulo, cfg.x + 0.006, cfg.y, cfg.escala, 140, 190, 255)

	if #linhas == 0 then
		escreverTexto(textos.painelVazio, cfg.x + 0.006, cfg.y + 0.03, cfg.escala, 200, 200, 200)
		return
	end

	local y = cfg.y + 0.03
	for _, linha in ipairs(linhas) do
		escreverTexto(linha.cabecalho, cfg.x + 0.006, y, cfg.escala, 255, 255, 255)
		escreverTexto(linha.pasta, cfg.x + 0.006, y + 0.022, cfg.escala - 0.03, 170, 170, 170)
		y = y + 0.052
	end
end

local function alternarPainel()
	painelLigado = not painelLigado
	painelAssinatura = ''
	avisar('aviso', painelLigado and textos.painelLigado or textos.painelDesligado)

	if not painelLigado then return end
	CreateThread(function()
		local proximaChecagem = 0
		while painelLigado do
			local agora = GetGameTimer()
			if agora >= proximaChecagem then
				proximaChecagem = agora + Config.painel.intervaloMs
				local ped, modelo = pedFreemode()
				if ped then atualizarPainel(ped, modelo) end
			end
			desenharPainel()
			Wait(0)
		end
	end)
end

local navegacao = nil -- { colecao, peca, numero, textura } da última roupa escolhida

local function vestir(ped, colecao, peca, numero, textura)
	local total = GetNumberOfPedCollectionDrawableVariations(ped, peca, colecao)
	if numero < 0 or numero >= total then
		return avisar('negado', textos.numeroNaoExiste:format(colecao, total, nomes[peca], total - 1, numero))
	end

	local slot = GetPedDrawableGlobalIndexFromCollection(ped, peca, colecao, numero)
	local texturas = GetNumberOfPedCollectionTextureVariations(ped, peca, colecao, numero)
	if textura < 0 or textura >= texturas then textura = 0 end

	SetPedComponentVariation(ped, peca, slot, textura, 0)
	navegacao = { colecao = colecao, peca = peca, numero = numero, textura = textura }
	avisar('sucesso', textos.vestiu:format(colecao, nomes[peca], numero, slot, textura))
end

local function vestirPorComando(ped, args)
	local peca = descobrirPeca(args[3])
	local numero = tonumber(args[4])
	if not args[2] or not peca or not numero then
		return avisar('negado', textos.usoVestir)
	end

	local colecao = acharColecao(ped, args[2])
	if not colecao then
		return avisar('negado', textos.colecaoNaoExiste:format(args[2]))
	end
	vestir(ped, colecao, peca, math.floor(numero), math.floor(tonumber(args[5]) or 0))
end

local function passar(direcao)
	local ped = pedFreemode()
	if not ped then return avisar('negado', textos.soFreemode) end
	if not navegacao then return avisar('negado', textos.navegacaoInativa) end

	local total = GetNumberOfPedCollectionDrawableVariations(ped, navegacao.peca, navegacao.colecao)
	if total <= 0 then return end
	local proximo = (navegacao.numero + direcao) % total
	vestir(ped, navegacao.colecao, navegacao.peca, proximo, 0)
end

RegisterCommand('roupaslot_proxima', function() passar(1) end, false)
RegisterCommand('roupaslot_anterior', function() passar(-1) end, false)
RegisterKeyMapping('roupaslot_proxima', 'Roupaslot: próxima roupa', 'keyboard', Config.teclas.proxima)
RegisterKeyMapping('roupaslot_anterior', 'Roupaslot: roupa anterior', 'keyboard', Config.teclas.anterior)

-----------------------------------------------------------------------------------------------------------------------------------------
-- /roupaslot buscar <texto>  ->  acha roupas pelo nome da pasta (o servidor procura, aqui só mostramos)
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('style_roupaslot:resultadoBusca', function(texto, total, achados)
	if total == 0 then
		return avisar('aviso', textos.buscaVazia:format(texto))
	end

	local ped = PlayerPedId()
	local linhas = {}
	for _, item in ipairs(achados) do
		local colecao, peca, numero, pasta = item[1], item[2], item[3], item[4]
		local slot = '?'
		local pecaNumero = numeroDaPeca[peca]
		if pecaNumero then
			local carregada = acharColecao(ped, colecao)
			if carregada and numero < GetNumberOfPedCollectionDrawableVariations(ped, pecaNumero, carregada) then
				slot = GetPedDrawableGlobalIndexFromCollection(ped, pecaNumero, carregada, numero)
			end
		end
		linhas[#linhas + 1] = ('%s_%s_%03d | slot %s | %s'):format(colecao, peca, numero, tostring(slot), pasta)
	end

	print(('^3[roupaslot] Busca por "%s":^7\n%s'):format(texto, table.concat(linhas, '\n')))
	avisar('sucesso', textos.buscaResumo:format(total, texto, #achados))
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- O servidor chama aqui depois de conferir a permissão
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('style_roupaslot:run', function(args)
	local ped, modelo = pedFreemode()
	if not ped then
		return avisar('negado', textos.soFreemode)
	end

	local acao = args[1] and args[1]:lower()
	if not acao then
		gerarDump(ped, modelo)
	elseif acao == 'slot' then
		consultarOrigem(ped, args)
	elseif acao == 'atual' then
		mostrarRoupaAtual(ped)
	elseif acao == 'colecoes' then
		mostrarColecoes(ped)
	elseif acao == 'painel' then
		alternarPainel()
	elseif acao == 'vestir' then
		vestirPorComando(ped, args)
	elseif acao == 'proxima' then
		passar(1)
	elseif acao == 'anterior' then
		passar(-1)
	elseif acao == 'buscar' then
		local texto = table.concat(args, ' ', 2)
		if #texto < 2 then
			return avisar('negado', textos.usoBuscar)
		end
		TriggerServerEvent('style_roupaslot:buscar', modelo, texto)
	else
		consultarSlot(ped, args)
	end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- NUI INTERFACE MODERNA (PIERCER CLOTH SLOT)
-----------------------------------------------------------------------------------------------------------------------------------------
local isUiOpen = false

CreateThread(function()
	SetNuiFocus(false, false)
	SendNUIMessage({ action = 'close' })
end)

local function coletarDadosCompletos(cb)
	local ped, modelo = pedFreemode()
	if not ped then
		return cb({ error = 'not_freemode' })
	end

	local pecas, pedidos = {}, {}
	local totalSlots = 0
	local addonsCount = 0
	local totalColecoes = GetPedCollectionsCount(ped)

	-- 1. Coleta itens vestidos agora (0 a 11)
	for peca = 0, 11 do
		local slot = GetPedDrawableVariation(ped, peca)
		local textura = GetPedTextureVariation(ped, peca)
		local colecao, numero = acharOrigem(ped, peca, slot)
		local nomePeca = nomes[peca] or ('comp_' .. peca)

		pecas[#pecas + 1] = {
			componentId = peca,
			componentName = nomePeca,
			slot = slot,
			texture = textura,
			collection = colecao or 'base',
			number = numero or 0,
			folder = ''
		}

		if colecao and colecao ~= '' and colecao ~= 'base' then
			pedidos[#pedidos + 1] = { colecao, nomePeca, numero }
		end
	end

	-- 2. Coleta coleções carregadas
	local colecoes = {}
	for i = 0, totalColecoes - 1 do
		local col = GetPedCollectionName(ped, i) or ''
		if col ~= '' then
			addonsCount = addonsCount + 1
			local colTotal = 0
			local colMin, colMax = 999999, 0
			for peca = 0, 11 do
				local cnt = GetNumberOfPedCollectionDrawableVariations(ped, peca, col)
				if cnt > 0 then
					colTotal = colTotal + cnt
					local p0 = GetPedDrawableGlobalIndexFromCollection(ped, peca, col, 0)
					local pN = GetPedDrawableGlobalIndexFromCollection(ped, peca, col, cnt - 1)
					if p0 < colMin then colMin = p0 end
					if pN > colMax then colMax = pN end
				end
			end
			totalSlots = totalSlots + colTotal
			if colTotal > 0 then
				colecoes[#colecoes + 1] = {
					name = col,
					totalPieces = colTotal,
					slotMin = colMin,
					slotMax = colMax
				}
			end
		end
	end

	-- 3. Mapeia pastas usando o cache ou solicita ao server
	for _, item in ipairs(pecas) do
		if item.collection and item.collection ~= 'base' then
			local chave = ('%s|%s|%d'):format(item.collection, item.componentName, item.number)
			item.folder = painelCaminhos[chave] or ''
		end
	end

	cb({
		model = modelo,
		equippedCount = #pedidos,
		addonsCount = addonsCount,
		totalSlots = totalSlots,
		equipped = pecas,
		collections = colecoes
	})
end

RegisterNetEvent('piercer_clothslot:openUI', function()
	if isUiOpen then return end
	isUiOpen = true
	SetNuiFocus(true, true)

	coletarDadosCompletos(function(data)
		SendNUIMessage({
			action = 'open',
			data = data
		})
	end)
end)

RegisterNetEvent('piercer_clothslot:run', function(args)
	TriggerEvent('style_roupaslot:run', args)
end)

RegisterNUICallback('close', function(_, cb)
	isUiOpen = false
	SetNuiFocus(false, false)
	SendNUIMessage({ action = 'close' })
	cb({ ok = true })
end)

RegisterNUICallback('getEquippedData', function(_, cb)
	coletarDadosCompletos(cb)
end)

RegisterNUICallback('wear', function(data, cb)
	local ped = PlayerPedId()
	if ped and data and data.collection and data.pieceId and data.number then
		vestir(ped, data.collection, data.pieceId, data.number, 0)
		cb({ ok = true })
	else
		cb({ ok = false })
	end
end)

RegisterNUICallback('searchClothes', function(data, cb)
	local ped, modelo = pedFreemode()
	if not ped or not data or not data.query then
		return cb({})
	end

	local queryId = GetGameTimer()
	local handler
	handler = AddEventHandler('piercer_clothslot:searchResult', function(qId, results)
		if qId == queryId then
			RemoveEventHandler(handler)
			for _, item in ipairs(results) do
				local pecaNum = numeroDaPeca[item.piece]
				if pecaNum then
					local colName = acharColecao(ped, item.collection)
					if colName and item.number < GetNumberOfPedCollectionDrawableVariations(ped, pecaNum, colName) then
						item.slot = GetPedDrawableGlobalIndexFromCollection(ped, pecaNum, colName, item.number)
						item.pieceId = pecaNum
						item.pieceName = nomes[pecaNum] or item.piece
					end
				end
			end
			cb(results)
		end
	end)

	TriggerServerEvent('piercer_clothslot:searchNui', modelo, data.query, queryId)
end)

RegisterNUICallback('generateDump', function(_, cb)
	local ped, modelo = pedFreemode()
	if ped and modelo then
		gerarDump(ped, modelo)
		cb({ ok = true })
	else
		cb({ ok = false })
	end
end)

AddEventHandler('onResourceStop', function(res)
	if res == GetCurrentResourceName() and isUiOpen then
		SetNuiFocus(false, false)
	end
end)
