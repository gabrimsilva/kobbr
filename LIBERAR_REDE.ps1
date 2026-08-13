# ============================================================================
# LIBERAR ACESSO AO SISTEMA NA REDE LOCAL (porta 5173 / Vite)
# ============================================================================
# Clique com o botao direito neste arquivo > "Executar com o PowerShell".
# Ele vai pedir permissao de administrador para liberar a porta no Firewall
# e em seguida mostra o link que seu colega deve abrir.
# ============================================================================

# Auto-elevar para administrador se necessario
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$porta = 5173
$nomeRegra = "Vite Dev $porta"

# Criar regra de entrada se ainda nao existir (perfis Private e Domain)
if (-not (Get-NetFirewallRule -DisplayName $nomeRegra -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName $nomeRegra -Direction Inbound -Protocol TCP -LocalPort $porta -Action Allow -Profile Private,Domain | Out-Null
    Write-Host "Regra de firewall criada para a porta $porta." -ForegroundColor Green
} else {
    Write-Host "Regra de firewall ja existia para a porta $porta." -ForegroundColor Yellow
}

# Descobrir os IPs reais da maquina (ignorando virtuais e APIPA)
Write-Host ""
Write-Host "Links para o seu colega abrir no navegador (mesma rede):" -ForegroundColor Cyan
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
        $_.IPAddress -ne '127.0.0.1' -and
        $_.IPAddress -notlike '169.254.*' -and
        $_.InterfaceAlias -notlike '*vEthernet*' -and
        $_.InterfaceAlias -notlike '*WSL*' -and
        $_.InterfaceAlias -notlike '*Bluetooth*'
    } |
    ForEach-Object {
        Write-Host ("  http://{0}:{1}/   ({2})" -f $_.IPAddress, $porta, $_.InterfaceAlias) -ForegroundColor White
    }

Write-Host ""
Write-Host "Dica: use o IP da MESMA rede que o computador do seu colega." -ForegroundColor DarkGray
Write-Host "Mantenha o 'npm run dev' rodando enquanto ele testa." -ForegroundColor DarkGray
Write-Host ""
Read-Host "Pressione ENTER para fechar"
