# 🌐 Guia de Acesso via LAN (Rede Local)

## 📋 Configuração Atual

O servidor Vite já está configurado para aceitar conexões de outros dispositivos na rede:

```typescript
server: {
  host: true, // ✅ Permite acesso pela rede
  port: 5173,
  strictPort: false,
}
```

---

## 🚀 Como Acessar de Outro PC

### 1. Descobrir o IP do PC que está rodando o servidor

**No Windows (PC que está rodando `npm run dev`):**

```bash
ipconfig
```

Procure por:
- **IPv4 Address** (Endereço IPv4)
- Geralmente algo como: `192.168.1.100` ou `10.0.0.50`

**Exemplo de saída:**
```
Adaptador de Rede sem Fio Wi-Fi:

   Endereço IPv4. . . . . . . . . . . : 192.168.1.100
   Máscara de Sub-rede . . . . . . . : 255.255.255.0
   Gateway Padrão. . . . . . . . . . : 192.168.1.1
```

---

### 2. Iniciar o servidor (se ainda não estiver rodando)

No PC principal:

```bash
npm run dev
```

**Saída esperada:**
```
  VITE v5.x.x  ready in xxx ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: http://192.168.1.100:5173/
  ➜  press h + enter to show help
```

⚠️ **IMPORTANTE:** Anote o endereço que aparece em **Network**!

---

### 3. Acessar de outro PC na mesma rede

No outro PC (ou tablet/celular), abra o navegador e digite:

```
http://[IP_DO_SERVIDOR]:5173
```

**Exemplo:**
```
http://192.168.1.100:5173
```

---

## 🔥 Firewall do Windows

Se não conseguir acessar, pode ser o firewall bloqueando. Siga os passos:

### Opção 1: Permitir Node.js no Firewall (Recomendado)

1. Abra **Windows Defender Firewall**
2. Clique em **Permitir um aplicativo ou recurso através do Firewall do Windows Defender**
3. Clique em **Alterar configurações**
4. Clique em **Permitir outro aplicativo...**
5. Procure por `node.exe` (geralmente em `C:\Program Files\nodejs\node.exe`)
6. Marque **Privado** e **Público**
7. Clique em **Adicionar**

### Opção 2: Criar Regra Específica para a Porta 5173

**Via PowerShell (como Administrador):**

```powershell
New-NetFirewallRule -DisplayName "Vite Dev Server" -Direction Inbound -LocalPort 5173 -Protocol TCP -Action Allow
```

### Opção 3: Desabilitar Firewall Temporariamente (NÃO RECOMENDADO)

Apenas para teste rápido:

1. Abra **Windows Defender Firewall**
2. Clique em **Ativar ou desativar o Firewall do Windows Defender**
3. Desative para **Rede privada** (temporariamente)
4. Teste o acesso
5. **LEMBRE-SE DE REATIVAR DEPOIS!**

---

## 🧪 Testar Conexão

### No PC que está rodando o servidor:

```bash
# Verificar se a porta está aberta
netstat -an | findstr :5173
```

**Saída esperada:**
```
TCP    0.0.0.0:5173           0.0.0.0:0              LISTENING
TCP    [::]:5173              [::]:0                 LISTENING
```

### No outro PC:

```bash
# Testar se consegue alcançar o servidor
ping 192.168.1.100

# Testar se a porta está acessível (PowerShell)
Test-NetConnection -ComputerName 192.168.1.100 -Port 5173
```

---

## 📱 Acessar de Celular/Tablet

1. Conecte o dispositivo na **mesma rede Wi-Fi**
2. Abra o navegador
3. Digite: `http://[IP_DO_SERVIDOR]:5173`

**Exemplo:**
```
http://192.168.1.100:5173
```

---

## 🔧 Solução de Problemas

### Problema 1: "Não foi possível acessar o site"

**Causas possíveis:**
- ❌ Dispositivos não estão na mesma rede
- ❌ Firewall bloqueando
- ❌ IP incorreto
- ❌ Servidor não está rodando

**Soluções:**
1. Verificar se ambos os dispositivos estão na mesma rede Wi-Fi
2. Verificar firewall (ver seção acima)
3. Confirmar IP com `ipconfig`
4. Confirmar que `npm run dev` está rodando

---

### Problema 2: "ERR_CONNECTION_REFUSED"

**Causa:** Servidor não está escutando na porta correta

**Solução:**
```bash
# Parar o servidor (Ctrl+C)
# Iniciar novamente
npm run dev
```

---

### Problema 3: IP muda toda vez

**Causa:** DHCP atribuindo IP dinâmico

**Solução:** Configurar IP estático no roteador

1. Acesse o painel do roteador (geralmente `192.168.1.1`)
2. Procure por **DHCP Reservation** ou **IP Estático**
3. Associe o MAC Address do PC a um IP fixo

---

## 🎯 Exemplo Completo

### PC Principal (192.168.1.100):
```bash
# 1. Verificar IP
ipconfig
# Resultado: 192.168.1.100

# 2. Iniciar servidor
npm run dev
# Servidor rodando em http://192.168.1.100:5173
```

### Outro PC (192.168.1.101):
```
# 1. Abrir navegador
# 2. Digitar: http://192.168.1.100:5173
# 3. Sistema deve carregar normalmente
```

---

## 📊 Verificação Rápida

Use este checklist:

- [ ] Servidor está rodando (`npm run dev`)
- [ ] IP do servidor foi identificado (`ipconfig`)
- [ ] Ambos os dispositivos estão na mesma rede
- [ ] Firewall permite conexões na porta 5173
- [ ] URL correta: `http://[IP]:5173`
- [ ] Navegador atualizado

---

## 🔒 Segurança

⚠️ **IMPORTANTE:**

- Este servidor é apenas para **desenvolvimento**
- **NÃO** exponha para a internet
- Use apenas em **rede local confiável**
- Para produção, use build (`npm run build`) e servidor adequado

---

## 💡 Dicas

### Usar QR Code para facilitar acesso mobile

1. Instale um gerador de QR Code online
2. Gere QR Code com a URL: `http://192.168.1.100:5173`
3. Escaneie com o celular
4. Acesso direto!

### Adicionar ao package.json

Você pode criar um script para mostrar o IP automaticamente:

```json
{
  "scripts": {
    "dev": "vite",
    "dev:lan": "vite --host"
  }
}
```

Então use:
```bash
npm run dev:lan
```

---

## 📞 Suporte

Se ainda tiver problemas:

1. Verifique se o antivírus não está bloqueando
2. Tente desabilitar VPN (se estiver usando)
3. Reinicie o roteador
4. Reinicie ambos os PCs

---

**Última atualização:** 27/02/2026  
**Configuração testada:** Windows 10/11 + Vite 5.x

