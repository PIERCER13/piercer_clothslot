Config = {}

-- Comandos que abrem a interface NUI do clothslot
Config.comandos = {
	'clothslot',
	'roupaslot'
}

-- Permissões necessárias
Config.permissao = 'admin.acess'
Config.permissoesBridge = { 'admin', 'Admin', 'admin.acess', 'superadmin', 'owner' }

-- Quanto tempo (em ms) as notificações ficam na tela
Config.tempoNotificacao = 8000

-- Limite de bytes por segundo ao enviar o dump para o servidor
-- (a lista é grande, então vai em pedaços para não travar a conexão)
Config.velocidadeEnvio = 200000

-- Teclas para passar para a próxima ou anterior roupa da coleção (cada admin pode trocar em Configurações > Teclas)
Config.teclas = {
	proxima  = 'PAGEDOWN',
	anterior = 'PAGEUP',
}

-- Painel que mostra, na tela, onde está na pasta cada roupa que você veste
-- (posições vão de 0.0 a 1.0, contando da esquerda e de cima)
Config.painel = {
	x = 0.012,
	y = 0.30,
	largura = 0.34,
	escala = 0.27,
	intervaloMs = 400, -- de quanto em quanto tempo confere se a roupa mudou
}

-- Personagens que o sistema atende
Config.modelos = {
	'mp_m_freemode_01', -- masculino
	'mp_f_freemode_01', -- feminino
}

-- Componentes de roupa, na ordem do jogo (0 a 11)
Config.componentes = {
	[0]  = 'head',
	[1]  = 'berd', -- máscara
	[2]  = 'hair', -- cabelo
	[3]  = 'uppr', -- mãos / tronco
	[4]  = 'lowr', -- calça
	[5]  = 'hand', -- mochila
	[6]  = 'feet', -- sapato
	[7]  = 'teef', -- acessório
	[8]  = 'accs', -- blusa
	[9]  = 'task', -- colete
	[10] = 'decl', -- adesivo
	[11] = 'jbib', -- jaqueta
}

-- Textos que o admin vê. Use %s e %d onde o script precisa preencher um valor.
Config.textos = {
	-- avisos gerais
	soFreemode      = 'Esse comando só funciona com o personagem freemode (masculino ou feminino).',
	semResultado    = 'Não achei nada com esses dados.',

	-- como usar
	usoConsulta     = 'Como usar: /roupaslot <coleção> <peça> <número>. Exemplo: /roupaslot addon5 jbib 51',
	usoReverso      = 'Como usar: /roupaslot slot <peça> <slot>. Exemplo: /roupaslot slot jbib 500',

	-- consulta direta e reversa
	colecaoNaoExiste = 'A coleção "%s" não está carregada. Digite /roupaslot colecoes para ver as que existem.',
	numeroNaoExiste  = 'A coleção %s tem %d itens de %s (de 0 a %d), então o %d não existe.',
	achouSlot        = '%s_%s_%03d fica no slot %d dentro do jogo (%d texturas).',
	achouOrigem      = 'O slot %d de %s vem de %s, número %03d.',
	slotNaoExiste    = 'O slot %d de %s não existe.',
	roupaBase        = 'roupa base do jogo',

	-- atual e coleções
	vejaConsole      = 'Prontinho! Os detalhes estão no console (F8).',
	colecoesCarregadas = 'Encontrei %d coleções carregadas. O resumo está no console (F8).',

	-- painel na tela
	painelLigado     = 'Painel ligado. Digite /roupaslot painel de novo para desligar.',
	painelDesligado  = 'Painel desligado.',
	painelTitulo     = 'ROUPAS NO CORPO  (pasta do style-cloth-addon)',
	painelSemPasta   = 'pasta não encontrada (rode o gerar_indice.ps1)',
	painelBase       = 'roupa base do jogo, sem pasta',
	painelVazio      = 'Nenhuma roupa addon vestida agora.',
	painelDuvidoso   = '  (!) numeração com buracos, confira a pasta',

	-- vestir e navegar
	vestiu           = 'Vestindo %s_%s_%03d (slot %d, textura %d).',
	usoVestir        = 'Como usar: /roupaslot vestir <coleção> <peça> <número> [textura]. Exemplo: /roupaslot vestir addon5 jbib 51',
	navegacaoInativa = 'Escolha primeiro uma coleção com /roupaslot vestir <coleção> <peça> <número>.',

	-- busca por nome de pasta
	usoBuscar        = 'Como usar: /roupaslot buscar <texto do nome da pasta>. Exemplo: /roupaslot buscar deado',
	buscaVazia       = 'Nenhuma roupa tem "%s" no nome da pasta.',
	buscaResumo      = 'Achei %d roupas com "%s" (mostrando %d). A lista está no console (F8).',

	-- dump
	dumpEnviando    = 'Lendo todas as roupas e enviando para o servidor (%d no total)...',
	dumpSalvo        = 'Dump salvo em %s.',
	dumpSemMudanca   = 'Nada mudou desde o último dump.',
	dumpMudancas     = 'O que mudou: %s',
}
