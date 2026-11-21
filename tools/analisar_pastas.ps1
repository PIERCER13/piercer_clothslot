# Confere as pastas do style-cloth-addon e gera um relatório em planilha.
#   powershell -ExecutionPolicy Bypass -File analisar_pastas.ps1
#
# O que ele faz:
#   - lista números faltando no meio da sequência (ex: tem jbib_050 e jbib_052, mas não o 051)
#   - lista roupas sem textura (.ytd)
#   - lista coleções que estão no stream mas não têm .meta na pasta data
#   - gera o relatorio_roupas.csv com todas as roupas (abre no Excel)

param(
	[string]$Cloth  = (Join-Path $PSScriptRoot '..\..\..\[framezero-cloth]\style-cloth-addon'),
	[string]$Saida  = (Join-Path $PSScriptRoot '..\data\relatorio_roupas.csv')
)

$Cloth  = (Resolve-Path -LiteralPath $Cloth).Path
$Stream = Join-Path $Cloth 'stream'
$Data   = Join-Path $Cloth 'data'

$padraoModelo  = '^(mp_[mf]_freemode_01)_(addon\d*)\^([a-z]+)_(\d+)_[ur]\.ydd$'
$padraoTextura = '_diff_(\d+)_'

$roupas   = @{}  # modelo|colecao|peca|numero -> pasta
$texturas = @{}  # pasta -> quantidade de .ytd por numero  (chave: pasta|numero)

foreach ($arquivo in Get-ChildItem -LiteralPath $Stream -Recurse -File) {
	$pasta = $arquivo.DirectoryName.Substring($Stream.Length).TrimStart('\') -replace '\\', '/'

	if ($arquivo.Extension -eq '.ydd' -and $arquivo.Name -match $padraoModelo) {
		$chave = '{0}|{1}|{2}|{3}' -f $Matches[1], $Matches[2], $Matches[3], [int]$Matches[4]
		if (-not $roupas.ContainsKey($chave)) { $roupas[$chave] = $pasta }
	}
	elseif ($arquivo.Extension -eq '.ytd' -and $arquivo.Name -match $padraoTextura) {
		$chaveTex = '{0}|{1}' -f $pasta, [int]$Matches[1]
		$texturas[$chaveTex] = 1 + [int]$texturas[$chaveTex]
	}
}

# ---- relatório CSV -------------------------------------------------------------------------------------------------------------------
$linhas = New-Object System.Collections.Generic.List[string]
$linhas.Add('modelo;colecao;peca;numero;texturas;pasta')
$semTextura = New-Object System.Collections.Generic.List[string]

foreach ($chave in ($roupas.Keys | Sort-Object)) {
	$p = $chave -split '\|'
	$pasta = $roupas[$chave]
	$qtd = [int]$texturas[('{0}|{1}' -f $pasta, [int]$p[3])]
	$linhas.Add(('{0};{1};{2};{3};{4};{5}' -f $p[0], $p[1], $p[2], $p[3], $qtd, $pasta))
	if ($qtd -eq 0) { $semTextura.Add(('{0} {1}_{2}_{3} ({4})' -f $p[0], $p[1], $p[2], $p[3].PadLeft(3, '0'), $pasta)) }
}
[System.IO.File]::WriteAllLines($Saida, $linhas, (New-Object System.Text.UTF8Encoding($true)))

# ---- números faltando ---------------------------------------------------------------------------------------------------------------
$grupos = @{}
foreach ($chave in $roupas.Keys) {
	$p = $chave -split '\|'
	$g = '{0}|{1}|{2}' -f $p[0], $p[1], $p[2]
	if (-not $grupos.ContainsKey($g)) { $grupos[$g] = New-Object System.Collections.Generic.List[int] }
	$grupos[$g].Add([int]$p[3])
}

$buracos = New-Object System.Collections.Generic.List[string]
foreach ($g in ($grupos.Keys | Sort-Object)) {
	$numeros = $grupos[$g] | Sort-Object
	$faltam = @()
	for ($n = 0; $n -le $numeros[-1]; $n++) {
		if ($numeros -notcontains $n) { $faltam += $n }
	}
	if ($faltam.Count -gt 0) {
		$buracos.Add(('{0}: faltam {1}' -f ($g -replace '\|', ' '), (($faltam | Select-Object -First 15) -join ', ') + $(if ($faltam.Count -gt 15) { ' ...' } else { '' })))
	}
}

# ---- coleções sem .meta ---------------------------------------------------------------------------------------------------------------
$semMeta = New-Object System.Collections.Generic.List[string]
foreach ($pastaColecao in Get-ChildItem -LiteralPath $Stream -Directory | Where-Object { $_.Name -match '^mp_[mf]_freemode_01_addon\d*$' }) {
	if (-not (Test-Path -LiteralPath (Join-Path $Data ($pastaColecao.Name + '.meta')))) {
		$semMeta.Add($pastaColecao.Name)
	}
}

# ---- resumo na tela ---------------------------------------------------------------------------------------------------------------------
function Mostrar($titulo, $lista) {
	Write-Host ''
	Write-Host ('{0}: {1}' -f $titulo, $lista.Count) -ForegroundColor Cyan
	$lista | Select-Object -First 40 | ForEach-Object { Write-Host ('  - ' + $_) }
	if ($lista.Count -gt 40) { Write-Host ('  ... e mais {0}' -f ($lista.Count - 40)) }
}

Write-Host ('{0} roupas analisadas. Planilha: {1}' -f $roupas.Count, $Saida) -ForegroundColor Green
Mostrar 'Numeros faltando na sequencia' $buracos
Mostrar 'Roupas sem textura (.ytd)' $semTextura
Mostrar 'Colecoes sem .meta' $semMeta
