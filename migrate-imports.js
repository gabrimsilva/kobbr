const fs = require('fs');
const path = require('path');
const glob = require('glob');

// Lista de services que devem ser migrados
const services = [
  'categoriaService',
  'pedidoService',
  'historicoPedidoService',
  'clienteService',
  'configuracaoService',
  'produtoService',
  'saborService',
  'adicionalService',
  'tamanhoService',
  'comboService',
  'authService',
  'funcionarioService',
  'estoqueService',
  'comandaService',
  'historicoComandaService'
];

function migrateImports(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  let modified = false;

  // Pattern para encontrar imports do supabase
  const importRegex = /import\s+{([^}]+)}\s+from\s+['"]@\/lib\/supabase['"]/g;

  content = content.replace(importRegex, (match, imports) => {
    const importList = imports.split(',').map(i => i.trim());
    const servicesToMigrate = [];
    const typesToKeep = [];
    const othersToKeep = [];

    importList.forEach(imp => {
      const importName = imp.replace(/^type\s+/, '');
      if (services.some(s => importName.includes(s))) {
        servicesToMigrate.push(imp);
      } else if (imp.startsWith('type ') || importName.endsWith('Supabase')) {
        typesToKeep.push(imp);
      } else if (importName === 'supabase') {
        othersToKeep.push(imp);
      } else {
        // Outro caso, manter
        othersToKeep.push(imp);
      }
    });

    let result = '';

    if (servicesToMigrate.length > 0) {
      result += `import { ${servicesToMigrate.join(', ')} } from '@/services'\n`;
      modified = true;
    }

    if (typesToKeep.length > 0 || othersToKeep.length > 0) {
      const keepList = [...typesToKeep, ...othersToKeep];
      result += `import { ${keepList.join(', ')} } from '@/lib/supabase'`;
    } else {
      // Remove a última quebra de linha se não há imports do supabase
      result = result.trimEnd();
    }

    return result;
  });

  if (modified) {
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`✅ Migrado: ${path.relative(process.cwd(), filePath)}`);
    return true;
  }

  return false;
}

// Encontrar todos os arquivos TypeScript/TSX
const files = glob.sync('src/**/*.{ts,tsx}', {
  ignore: ['node_modules/**', 'dist/**', 'src/lib/supabase.ts']
});

let count = 0;
files.forEach(file => {
  if (migrateImports(file)) {
    count++;
  }
});

console.log(`\n📊 Total de arquivos migrados: ${count}`);
