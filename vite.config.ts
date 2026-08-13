import path from "path"
import tailwindcss from "@tailwindcss/vite"
import react from "@vitejs/plugin-react"
import { defineConfig } from "vite"
import { securityHeadersPlugin } from "./vite-plugin-security-headers"

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss(), securityHeadersPlugin()],
  server: {
    host: true, // Permite acesso pela rede
    port: 5173,
    strictPort: false,
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          // Separar React e ReactDOM
          'react-vendor': ['react', 'react-dom'],
          
          // Separar Lucide icons
          'lucide': ['lucide-react'],
          
          // Separar Supabase
          'supabase': ['@supabase/supabase-js'],
          
          // Separar UI components
          'ui-vendor': [
            '@radix-ui/react-alert-dialog',
            '@radix-ui/react-dialog', 
            '@radix-ui/react-separator',
            '@radix-ui/react-slot'
          ],
          
          // Separar drag and drop
          'dnd': ['@hello-pangea/dnd'],
          
          // Separar outras dependências grandes
          'utils': ['clsx', 'tailwind-merge', 'class-variance-authority']
        }
      }
    },
    // Aumentar o limite de aviso para 600KB
    chunkSizeWarningLimit: 600,
    
    // Otimizações adicionais
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true, // Remove console.logs em produção
        drop_debugger: true
      }
    }
  }
})
