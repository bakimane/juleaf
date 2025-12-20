# 📝 Juleaf (Overleaf like on julia)

> A free, open-source alternative to Overleaf for Julia developers. Write academic papers with live code execution and instant PDF preview.

![Julia](https://img.shields.io/badge/Julia-1.9+-9558B2?logo=julia)
![License](https://img.shields.io/badge/license-MIT-green)
![Status](https://img.shields.io/badge/status-stable-brightgreen)

## ✨ Features

- 🎨 **Split-pane interface** - Code on left, PDF preview on right
- ⚡ **Live compilation** - Auto-compiles 2 seconds after typing
- 📊 **Execute Julia code** - Run code blocks and embed plots directly
- 🔬 **Publication-ready** - LaTeX equations, CairoMakie plots, professional formatting
- 🚀 **No cloud dependency** - Runs completely offline on your machine
- 💯 **Pure Julia** - No Jupyter or Python required
- 🆓 **100% Free** - No subscriptions, no limits

Perfect for research papers, technical reports, and scientific documentation.

---

## 📋 Prerequisites

### 1. Install Homebrew (macOS)
If you don't have Homebrew:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install Julia
Download from [julialang.org](https://julialang.org/downloads/) or via Homebrew:
```bash
brew install julia
```

Verify installation:
```bash
julia --version
# Should show: julia version 1.9 or higher
```

### 3. Install LaTeX Engine
Choose **one** option:

**Option A: TinyTeX** (Recommended - smaller, ~200MB)
```bash
brew install quarto
quarto install tinytex
```

**Option B: MacTeX** (Full distribution, ~4GB)
```bash
brew install --cask mactex-no-gui
```

### 4. Configure PATH for TinyTeX (if using Option A)
Add TinyTeX to your shell:
```bash
echo 'export PATH="$HOME/Library/TinyTeX/bin/universal-darwin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Verify:
```bash
which xelatex
# Should output: /Users/[your-username]/Library/TinyTeX/bin/universal-darwin/xelatex
```

---

## 🚀 Installation

### 1. Clone or Download
```bash
git clone https://github.com/yourusername/julia-weave-editor.git
cd julia-weave-editor
```

Or download the three files:
- `server.jl`
- `editor.html`
- `README.md`

### 2. Install Julia Dependencies
Start Julia **in the project directory**:
```bash
cd julia-weave-editor
julia --project=.
```

In the Julia REPL:
```julia
using Pkg
Pkg.activate(".")
Pkg.add(["HTTP", "Weave", "CairoMakie"])
```

Wait for installation to complete (first time may take a few minutes).

---

## 🎯 Usage

### Start the Server
From the project directory:
```bash
julia --project=. server.jl
```

You should see:
```
Starting Overleaf-like server on http://localhost:8080
Press Ctrl+C to stop
```

### Open in Browser
Navigate to: **http://localhost:8080**

### Using the Editor

1. **Edit code** in the left pane
2. **Auto-compile**: Waits 2 seconds after you stop typing
3. **Manual compile**: Click "Compile" button or press `Cmd+S` (Mac) / `Ctrl+S` (Windows/Linux)
4. **View PDF** in the right pane

### Example Document Syntax

```julia
---
title: "My Research Paper"
---

## Introduction

This is a scientific document with executable Julia code.

```julia
using CairoMakie

# Generate data
x = range(0, 10, 100)
y = sin.(x) .* exp.(-0.1x)

# Create plot
fig = Figure(size = (600, 400))
ax = Axis(fig[1, 1], 
    xlabel = "Time (s)", 
    ylabel = "Amplitude",
    title = "Damped Oscillation"
)
lines!(ax, x, y, color = :blue, linewidth = 2)
fig
```

## Results

The plot above shows exponential decay with the equation:

$$
y(t) = \sin(t) \cdot e^{-0.1t}
$$
```

---

## 🛠️ Troubleshooting

### "Package HTTP not found"
```bash
cd your-project-directory
julia --project=.
```
Then in Julia:
```julia
using Pkg
Pkg.add(["HTTP", "Weave", "CairoMakie"])
```

### "could not spawn xelatex"
- Verify LaTeX installation: `which xelatex`
- If empty, reinstall TinyTeX or add to PATH
- Restart Julia after installing LaTeX

### "Compilation failed"
- Check browser console (F12) for errors
- View terminal output for detailed error messages
- Ensure all Julia packages are installed

### Port 8080 already in use
Edit `server.jl` and change:
```julia
const PORT = 8080  # Change to 3000 or another port
```

---

## 📦 What You Get

The app includes:
- Full markdown support
- LaTeX equation rendering
- Julia code execution
- CairoMakie plot generation
- Automatic PDF compilation
- Keyboard shortcuts
- Live preview updates

---

## 🔧 Advanced Usage

### Custom Port
```julia
# In server.jl
const PORT = 3000  # Use any available port
```

### Additional Packages
Install any Julia package for use in documents:
```julia
using Pkg
Pkg.add("DataFrames")  # Example
```

Then use in your `.jmd` files:
```julia
using DataFrames
df = DataFrame(A = 1:4, B = ["M", "F", "F", "M"])
```

---

## 🚀 Future Enhancements

- [ ] Syntax highlighting (CodeMirror integration)
- [ ] Multiple file support
- [ ] Project save/load functionality
- [ ] Export to HTML, Word, Markdown
- [ ] Collaborative editing (WebSockets)
- [ ] Dark mode
- [ ] Custom themes
- [ ] BibTeX support

---

## 📜 Requirements Summary

| Component | Version | Required |
|-----------|---------|----------|
| Julia | ≥ 1.9 | ✅ |
| HTTP.jl | Latest | ✅ |
| Weave.jl | Latest | ✅ |
| CairoMakie.jl | Latest | ✅ |
| TinyTeX or MacTeX | Any | ✅ |

---

## 🤝 Contributing

Contributions welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests
- Improve documentation

---

## 📄 License

MIT License - Free for personal and commercial use.

---

## 💡 Why This Exists

Overleaf is great but requires internet and has limitations. This project provides:
- **Complete offline functionality**
- **No usage limits**
- **Full Julia integration**
- **Zero cost**
- **Privacy** (your documents stay on your machine)

Perfect for researchers, students, and anyone writing technical documents with Julia.

---

## 📧 Support

Having issues? 
1. Check the Troubleshooting section
2. Review the Prerequisites
3. Open an issue on GitHub

---

**Built with ❤️ for the Julia community**
