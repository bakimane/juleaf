# 🍃 Juleaf

**Julia + Weave + LaTeX** — Scientific documents with executable code.

![License](https://img.shields.io/badge/license-MIT-blue.svg)

## Features

- 📝 Julia code execution in documents
- 📐 LaTeX math rendering
- 📄 PDF output (IEEE, Beamer, Article, Letter)
- ✨ AI assist (Groq/Claude)
- 🌙 Dark mode

## Install

### 1. Julia

**macOS**
```bash
brew install julia
```

**Ubuntu/Debian**
```bash
curl -fsSL https://install.julialang.org | sh
```

**Windows**  
Download from [julialang.org/downloads](https://julialang.org/downloads/)

### 2. TinyTeX (LaTeX)

**macOS/Linux**
```bash
curl -sL "https://yihui.org/tinytex/install-bin-unix.sh" | sh
```

**Windows**
```powershell
Invoke-WebRequest -Uri "https://yihui.org/tinytex/install-windows.bat" -OutFile "install.bat"; .\install.bat
```

### 3. Pandoc

**macOS**
```bash
brew install pandoc
```

**Ubuntu/Debian**
```bash
sudo apt install pandoc
```

**Windows**  
Download from [pandoc.org](https://pandoc.org/installing.html)

### 4. Juleaf

```bash
git clone https://github.com/YOUR_USERNAME/juleaf.git
cd juleaf
julia -e 'using Pkg; Pkg.add(["HTTP", "Weave"])'
julia server.jl
```

Open http://localhost:8080

## Templates

| Template | Use Case |
|----------|----------|
| Article | Reports, papers |
| IEEE | Conference papers |
| Beamer | Presentations |
| Letter | Formal letters |
| Math | Theorems, proofs |

## Shortcuts

| Key | Action |
|-----|--------|
| `Ctrl+S` | Save + Compile |
| `Ctrl+Enter` | Compile |
| `Ctrl+I` | AI assist |

## AI (Optional)

1. Get free key at [console.groq.com](https://console.groq.com)
2. Click ✨ AI → paste key

## License

MIT
