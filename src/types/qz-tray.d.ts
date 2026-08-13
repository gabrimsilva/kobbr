declare module 'qz-tray' {
  interface QZWebsocket {
    connect(): Promise<void>
    disconnect(): Promise<void>
    isActive(): boolean
  }

  interface QZPrinters {
    find(): Promise<string[]>
  }

  interface QZConfig {
    // Config methods
  }

  interface QZConfigs {
    create(printer: string): QZConfig
  }

  interface QZData {
    type: 'html' | 'raw' | 'pixel'
    format: 'plain' | 'command' | 'image'
    data: string
  }

  interface QZ {
    websocket: QZWebsocket
    printers: QZPrinters
    configs: QZConfigs
    print(config: QZConfig, data: QZData[]): Promise<void>
  }

  const qz: QZ
  export default qz
}
