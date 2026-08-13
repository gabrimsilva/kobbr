// Serviço para gerenciar notificações sonoras
export class AudioService {
  private static instance: AudioService
  private audioContext: AudioContext | null = null
  private sounds: { [key: string]: HTMLAudioElement } = {}

  private constructor() {
    this.initializeAudioContext()
    this.preloadSounds()
  }

  public static getInstance(): AudioService {
    if (!AudioService.instance) {
      AudioService.instance = new AudioService()
    }
    return AudioService.instance
  }

  private initializeAudioContext() {
    try {
      // Criar contexto de áudio para navegadores modernos
      this.audioContext = new (window.AudioContext || (window as any).webkitAudioContext)()
    } catch (error) {
      // AudioContext não suportado
    }
  }

  private preloadSounds() {
    const soundFiles = [
      { key: 'ding1', path: '/sounds/ding1.mp3', name: 'Ding Clássico' },
      { key: 'ding2', path: '/sounds/ding2.mp3', name: 'Ding Moderno' },
      { key: 'ding3', path: '/sounds/ding3.mp3', name: 'Ding Suave' }
    ]

    soundFiles.forEach(({ key, path }) => {
      const audio = new Audio(path)
      audio.preload = 'auto'
      audio.volume = 0.7

      // Lidar com erros de carregamento
      audio.addEventListener('error', () => {
        // Arquivo de som não encontrado
      })

      this.sounds[key] = audio
    })
  }

  public async playNotification(soundKey: string = 'ding1') {
    try {
      // Garantir que o contexto de áudio está ativo
      if (this.audioContext && this.audioContext.state === 'suspended') {
        await this.audioContext.resume()
      }

      const audio = this.sounds[soundKey]
      if (audio && audio.readyState >= 2) { // HAVE_CURRENT_DATA ou superior
        // Resetar o áudio para o início
        audio.currentTime = 0
        await audio.play()
      }
    } catch (error) {
      // Erro ao reproduzir notificação sonora
    }
  }

  public getSoundOptions() {
    return [
      { key: 'ding1', name: 'Ding Clássico' },
      { key: 'ding2', name: 'Ding Moderno' },
      { key: 'ding3', name: 'Ding Suave' },
      { key: 'none', name: 'Sem som' }
    ]
  }

  public setVolume(volume: number) {
    Object.values(this.sounds).forEach(audio => {
      audio.volume = Math.max(0, Math.min(1, volume))
    })
  }

  public testSound(soundKey: string) {
    this.playNotification(soundKey)
  }
}

export const audioService = AudioService.getInstance()