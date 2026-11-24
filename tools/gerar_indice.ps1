param(
	[string]$Stream = (Join-Path $PSScriptRoot '..\..\..\[framezero-cloth]\style-cloth-addon\stream'),
	[string]$Saida  = (Join-Path $PSScriptRoot '..\data\index.lua')
)

$Stream = (Resolve-Path -LiteralPath $Stream).Path
$padrao = '^(mp_[mf]_freemode_01)_(addon\d*)\^([a-z]+)_(\d+)_[ur]\.ydd$'
$mapa = @{}

Get-ChildItem -LiteralPath $Stream -Recurse -File -Filter *.ydd | ForEach-Object {
	if ($_.Name -match $padrao) {
		$chave = '{0}|{1}|{2}|{3}' -f $Matches[1], $Matches[2], $Matches[3], [int]$Matches[4]
		if (-not $mapa.ContainsKey($chave)) {
			$pasta = $_.DirectoryName.Substring($Stream.Length).TrimStart('\') -replace '\\', '/'
			$mapa[$chave] = $pasta
		}
	}
}

$numerosPorGrupo = @{}
foreach ($chave in $mapa.Keys) {
	$p = $chave -split '\|'
	$g = '{0}|{1}|{2}' -f $p[0], $p[1], $p[2]
	if (-not $numerosPorGrupo.ContainsKey($g)) { $numerosPorGrupo[$g] = New-Object System.Collections.Generic.HashSet[int] }
	[void]$numerosPorGrupo[$g].Add([int]$p[3])
}
$duvidosos = New-Object System.Collections.Generic.List[string]
foreach ($g in $numerosPorGrupo.Keys) {
	$maior = ($numerosPorGrupo[$g] | Measure-Object -Maximum).Maximum
	if ($numerosPorGrupo[$g].Count -le $maior) { $duvidosos.Add($g) }
}

$linhas = New-Object System.Collections.Generic.List[string]
$linhas.Add('-- Arquivo gerado por gerar_indice.ps1. Nao edite na mao.')
$linhas.Add('return {')
$linhas.Add('	caminhos = {')
foreach ($chave in ($mapa.Keys | Sort-Object)) {
	$valor = $mapa[$chave] -replace '\\', '\\' -replace '"', '\"'
	$linhas.Add(('		["{0}"] = "{1}",' -f $chave, $valor))
}
$linhas.Add('	},')
$linhas.Add('	duvidosos = {')
foreach ($g in ($duvidosos | Sort-Object)) {
	$linhas.Add(('		["{0}"] = true,' -f $g))
}
$linhas.Add('	},')
$linhas.Add('}')

[System.IO.File]::WriteAllLines($Saida, $linhas, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("Pronto: {0} roupas indexadas em {1} ({2} grupos com numeracao duvidosa)" -f $mapa.Count, $Saida, $duvidosos.Count)
