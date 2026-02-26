# Examples Directory

This directory contains working demo files for the BlackRoad Dashboards web integration.

## File Organization

### Duplicated Files (Intentional)
The following files are duplicated from parent directories for the demo to work with simple HTTP servers:

- `dashboard-core.css` - Copy of `../css/dashboard-core.css`
- `dashboard-core.js` - Copy of `../js/dashboard-core.js`
- `system-dashboard.js` - Copy of `../components/system-dashboard.js`

**Why?** Simple HTTP servers (like Python's `http.server`) don't allow directory traversal for security reasons. These copies allow the demo to work standalone.

### Production Use
In production, use the canonical files from their original locations:
- CSS: `web-dashboards/css/dashboard-core.css`
- JS: `web-dashboards/js/dashboard-core.js`
- Components: `web-dashboards/components/*.js`

Or use a bundler/CDN that properly handles paths.

## Running the Demo

```bash
cd web-dashboards/examples
python3 -m http.server 8080
# Open http://localhost:8080
```

## Integration in Real Projects

For actual website integration, reference the canonical files:

```html
<link rel="stylesheet" href="/path/to/web-dashboards/css/dashboard-core.css">
<script src="/path/to/web-dashboards/js/dashboard-core.js"></script>
<script src="/path/to/web-dashboards/components/system-dashboard.js"></script>
```

Or use the WordPress plugin which handles paths automatically.
