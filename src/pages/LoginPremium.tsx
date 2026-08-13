import { useState } from 'react'
import { Eye, EyeOff, ArrowRight } from 'lucide-react'
import './LoginPremium.css'

export default function LoginPremium() {
  const [estabelecimento, setEstabelecimento] = useState('CIC')
  const [email, setEmail] = useState('')
  const [senha, setSenha] = useState('')
  const [mostrarSenha, setMostrarSenha] = useState(false)
  const [lembrarMe, setLembrarMe] = useState(false)
  const [carregando, setCarregando] = useState(false)

  const handleEntrar = async (e: React.FormEvent) => {
    e.preventDefault()
    setCarregando(true)
    // Simular login
    setTimeout(() => {
      console.log('Login:', { estabelecimento, email, senha })
      setCarregando(false)
    }, 1000)
  }

  return (
    <div className="login-premium-container">
      {/* Background com gradiente e texturas */}
      <div className="login-bg-gradient"></div>
      <div className="login-bg-texture"></div>
      <div className="login-bg-ambient"></div>

      {/* Conteúdo Principal */}
      <div className="login-content">
        {/* Lado Esquerdo - 60% */}
        <div className="login-left">
          {/* Background com imagens */}
          <div className="login-left-bg">
            {/* Foto do Pastor - Background */}
            <div className="pastor-bg-container">
              <img 
                src="/img/pastor.jpg" 
                alt="Pastor" 
                className="pastor-image"
                onError={(e) => {
                  e.currentTarget.style.display = 'none'
                }}
              />
            </div>

            {/* Santa Ceia - Bottom */}
            <div className="santa-ceia-container">
              <img 
                src="/img/santa-ceia.jpg" 
                alt="Santa Ceia" 
                className="santa-ceia-image"
                onError={(e) => {
                  e.currentTarget.style.display = 'none'
                }}
              />
            </div>
          </div>

          {/* Conteúdo Esquerdo Overlay */}
          <div className="login-left-content">
            {/* Logo */}
            <div className="logo-container">
              <img 
                src="/img/logo-videira.png" 
                alt="Videira Logo" 
                className="logo-image"
                onError={(e) => {
                  e.currentTarget.style.display = 'none'
                }}
              />
            </div>

            {/* Título */}
            <div className="title-section">
              <h1 className="title-line-1">Portal de Gestão</h1>
              <h1 className="title-line-2">Restaurante</h1>
              <p className="subtitle">Comunidade Videira</p>
            </div>

            {/* Descrição */}
            <div className="description-section">
              <p className="description-text">
                Gerencie a cantina da igreja com excelência.<br />
                Sirva com amor.<br />
                Alimente propósitos.
              </p>
            </div>

            {/* Versículo Card */}
            <div className="verse-card">
              <svg className="verse-quote" width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M3 21c3 0 7-1 7-8V5c0-1.25-4.4-4.5-7-4.5-1.5 0-3 1-3 3v12c0 2 1 3 3 3z" stroke="currentColor" strokeWidth="2" fill="none"/>
                <path d="M15 21c3 0 7-1 7-8V5c0-1.25-4.4-4.5-7-4.5-1.5 0-3 1-3 3v12c0 2 1 3 3 3z" stroke="currentColor" strokeWidth="2" fill="none"/>
              </svg>
              <p className="verse-text">
                "Tudo quanto fizerdes, fazei-o de todo o coração, como para o Senhor e não para homens."
              </p>
              <p className="verse-reference">Colossenses 3:23</p>
            </div>
          </div>
        </div>

        {/* Lado Direito - 40% */}
        <div className="login-right">
          {/* Login Card */}
          <div className="login-card">
            {/* Header */}
            <div className="login-header">
              <h2>Bem-vindo(a)!</h2>
              <p>Faça login para acessar o sistema de gestão da cantina.</p>
            </div>

            {/* Form */}
            <form className="login-form" onSubmit={handleEntrar}>
              {/* Estabelecimento */}
              <div className="form-group">
                <label htmlFor="estab" className="form-label">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                    <polyline points="9 22 9 12 15 12 15 22"></polyline>
                  </svg>
                  Estabelecimento
                </label>
                <select
                  id="estab"
                  value={estabelecimento}
                  onChange={(e) => setEstabelecimento(e.target.value)}
                  className="form-input form-select"
                >
                  <option value="CIC">CIC - Comunidade Inicial</option>
                  <option value="VIDEIRA">Videira - Sede</option>
                </select>
              </div>

              {/* Email */}
              <div className="form-group">
                <label htmlFor="email" className="form-label">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <rect x="2" y="4" width="20" height="16" rx="2"></rect>
                    <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"></path>
                  </svg>
                  E-mail
                </label>
                <input
                  id="email"
                  type="email"
                  placeholder="Digite seu e-mail"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="form-input"
                  required
                />
              </div>

              {/* Senha */}
              <div className="form-group">
                <label htmlFor="senha" className="form-label">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                  </svg>
                  Senha
                </label>
                <div className="form-input-wrapper">
                  <input
                    id="senha"
                    type={mostrarSenha ? 'text' : 'password'}
                    placeholder="Digite sua senha"
                    value={senha}
                    onChange={(e) => setSenha(e.target.value)}
                    className="form-input"
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setMostrarSenha(!mostrarSenha)}
                    className="form-input-icon"
                  >
                    {mostrarSenha ? (
                      <EyeOff width={16} height={16} />
                    ) : (
                      <Eye width={16} height={16} />
                    )}
                  </button>
                </div>
              </div>

              {/* Checkbox e Link */}
              <div className="form-footer">
                <label className="checkbox-label">
                  <input
                    type="checkbox"
                    checked={lembrarMe}
                    onChange={(e) => setLembrarMe(e.target.checked)}
                    className="checkbox-input"
                  />
                  <span>Lembrar-me</span>
                </label>
                <a href="#" className="form-link">
                  Esqueceu sua senha?
                </a>
              </div>

              {/* Botão */}
              <button
                type="submit"
                className={`form-button ${carregando ? 'loading' : ''}`}
                disabled={carregando}
              >
                {carregando ? (
                  <>
                    <span className="spinner"></span>
                    Entrando...
                  </>
                ) : (
                  <>
                    Entrar
                    <ArrowRight width={16} height={16} />
                  </>
                )}
              </button>
            </form>

            {/* Footer */}
            <div className="login-card-footer">
              <div className="footer-logo">
                <img 
                  src="/img/logo-videira-small.png" 
                  alt="Videira" 
                  className="footer-logo-img"
                  onError={(e) => {
                    e.currentTarget.style.display = 'none'
                  }}
                />
                <span>Videira</span>
              </div>
              <p className="footer-text">
                Criado por <a href="https://oonsystems.tech" target="_blank" rel="noopener noreferrer">OonSystems</a>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
