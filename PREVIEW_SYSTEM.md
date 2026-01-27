# 🌐 Dashboard Template Browser

Visual preview system for all BlackRoad OS dashboard templates. Browse, search, and preview 128 beautiful terminal dashboards before running them.

## 🚀 Quick Start

### Launch the Template Browser

```bash
./preview-browser.sh
```

Or from the main launcher:

```bash
./launch.sh
# Select option 8: Browse All Templates
```

## ✨ Features

### 📊 Visual Previews
- Click any template to see a full visual preview with actual ANSI colors
- Real dashboard output captured and rendered in your browser
- See exactly what each dashboard looks like before running it

### 🔍 Search & Filter
- **Search**: Type to search by dashboard name or description
- **Filter by Category**: 
  - Core (11 templates) - Main BlackRoad OS dashboards
  - Monitoring (22 templates) - System and infrastructure monitoring
  - AI (12 templates) - AI agents and neural networks
  - Crypto (2 templates) - Cryptocurrency tracking
  - Infrastructure (7 templates) - Docker, databases, APIs
  - Visualization (4 templates) - Charts, graphs, 3D views
  - Security (2 templates) - Security monitoring and alerts
  - Sci-Fi (13 templates) - Quantum, cosmic, reality manipulation
  - General (42 templates) - Various utilities

### 🏷️ Template Metadata
Each template card shows:
- **Category** badge
- **Interactive** badge - Dashboard has keyboard controls
- **🔊 Sound** badge - Includes sound effects
- **API** badge - Integrates with external APIs

### 📈 Statistics
- Total templates available
- Currently filtered count
- Interactive dashboards count

## 🛠️ How It Works

### 1. Metadata Generation

```bash
./generate-previews.sh
```

This script:
- Scans all `.sh` files in the repository
- Extracts metadata (description, category, features)
- Generates `previews/templates.json`
- Categorizes templates automatically

### 2. Visual Preview Capture

```bash
./generate-visual-previews.sh
```

This script:
- Runs featured dashboards with a 2-second timeout
- Captures their terminal output with ANSI colors
- Saves screenshots to `previews/screenshots/`
- Currently captures 10+ featured dashboards

### 3. Web Interface

The browser interface (`previews/index.html`) provides:
- Beautiful card-based layout matching BlackRoad OS design
- Real-time search and filtering
- Modal preview with full ANSI color rendering
- Responsive design that works on any screen size

## 📁 File Structure

```
blackroad-dashboards/
├── generate-previews.sh          # Metadata extraction
├── generate-visual-previews.sh   # Screenshot capture
├── preview-browser.sh             # Launcher script
└── previews/
    ├── index.html                 # Web interface
    ├── templates.json             # Template metadata
    └── screenshots/               # Visual previews
        ├── blackroad-dashboard.txt
        ├── blackroad-live-dashboard.txt
        ├── blackroad-ultimate.txt
        └── ...
```

## 🎨 Template Categories

### Core Dashboards
The main BlackRoad OS experience:
- blackroad-dashboard.sh
- blackroad-live-dashboard.sh
- blackroad-full-system.sh
- blackroad-ultimate.sh
- blackroad-os95.sh
- blackroad-beautiful-os.sh

### Monitoring Dashboards
System and infrastructure monitoring:
- system-metrics-live.sh
- live-github-dashboard.sh
- database-monitor.sh
- docker-fleet.sh
- performance-profiler.sh

### AI & Neural Networks
AI agents and neural visualizations:
- agent-detail.sh
- agent-network-map.sh
- neural-network-viz.sh
- brain-computer-interface.sh
- ai-insights.sh

### And many more across all categories!

## 🔧 Customization

### Adding New Categories
Edit `generate-previews.sh` to add custom categories:

```bash
if [[ $script_name =~ (your|pattern) ]]; then
    category="your_category"
fi
```

### Generating More Previews
Edit `generate-visual-previews.sh` to add more dashboards to preview:

```bash
featured=(
    "your-dashboard.sh"
    # ... more dashboards
)
```

### Styling the Browser
Edit `previews/index.html` to customize:
- Colors (CSS variables)
- Layout (grid settings)
- Card design
- Modal appearance

## 💡 Usage Tips

1. **Browse First**: Use the template browser before running dashboards to find what you need
2. **Search Smart**: Search by keywords like "crypto", "agent", "monitor", etc.
3. **Filter by Category**: Narrow down to specific types of dashboards
4. **Preview Before Running**: Click to see exactly what the dashboard looks like
5. **Check Badges**: Look for Interactive, Sound, or API badges for special features

## 🚀 Launch Commands

From the preview browser, you'll see the exact command to run each dashboard:

```bash
./dashboard-name.sh              # Basic run
./dashboard-name.sh --watch      # Interactive mode (if available)
./dashboard-name.sh --boot       # Boot sequence (if available)
```

## 📝 Examples

### Example 1: Find Crypto Dashboards
1. Open preview browser: `./preview-browser.sh`
2. Click "Crypto" filter button
3. Browse 2 crypto-focused templates
4. Click to preview and launch

### Example 2: Search for Agent Monitors
1. Open preview browser
2. Type "agent" in search box
3. See all agent-related dashboards
4. Preview and select your favorite

### Example 3: Discover Interactive Dashboards
1. Open preview browser
2. Look for "Interactive" badges
3. These dashboards have keyboard controls
4. Perfect for live monitoring

## 🎯 Featured Dashboards

Check out these hand-picked favorites:

1. **blackroad-ultimate.sh** ⚡
   - ULTIMATE edition with sound, APIs, SSH menu
   - Interactive controls
   - The complete experience

2. **blackroad-os95.sh** 🪟
   - Retro Windows 95 UI
   - Boot sequence animation
   - Pure nostalgia

3. **agent-detail.sh** 🔍
   - Deep dive into individual agents
   - Tabbed interface
   - Resource monitoring

4. **neural-network-viz.sh** 🧠
   - Visualize neural networks
   - Real-time updates
   - AI in action

5. **quantum-simulator.sh** ⚛️
   - Quantum computing visualization
   - Sci-fi aesthetics
   - Mind-bending!

## 🤝 Contributing

Want to add more templates to the browser?

1. Create your dashboard script
2. Run `./generate-previews.sh` to update metadata
3. (Optional) Add to featured list in `generate-visual-previews.sh`
4. Run `./generate-visual-previews.sh` to capture preview

## 📜 License

Copyright © 2026 BlackRoad OS, Inc. All Rights Reserved.

---

**Created with 💜 for BlackRoad OS**

*Browse. Preview. Launch. 🚀*
