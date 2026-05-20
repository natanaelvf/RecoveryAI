/**
 * Router — Hash-based SPA routing
 * Routes: #/login, #/dashboard, #/leads, #/leads/:id, #/settings
 */

const routes = [];
let currentView = null;
let currentCleanup = null;

/**
 * Register a route
 * @param {string} pattern - Route pattern (e.g., '/leads/:id')
 * @param {(params: Record<string, string>) => { render: () => string|HTMLElement, mount?: () => void, cleanup?: () => void }} handler
 */
export function route(pattern, handler) {
  // Convert pattern to regex: /leads/:id → /leads/([^/]+)
  const paramNames = [];
  const regexStr = pattern.replace(/:(\w+)/g, (_, name) => {
    paramNames.push(name);
    return '([^/]+)';
  });
  routes.push({
    pattern,
    regex: new RegExp(`^${regexStr}$`),
    paramNames,
    handler,
  });
}

/**
 * Navigate to a hash route
 * @param {string} path
 */
export function navigate(path) {
  window.location.hash = path;
}

/**
 * Get current route path
 */
export function getCurrentPath() {
  return window.location.hash.slice(1) || '/login';
}

/**
 * Start the router — listens for hash changes and renders
 */
export function startRouter() {
  const handleRoute = () => {
    const path = getCurrentPath();
    console.log('[Router] Handling route:', path);

    // Cleanup previous view
    try {
      if (currentCleanup) {
        currentCleanup();
        currentCleanup = null;
      }
    } catch (err) {
      console.error('[Router] Error in cleanup:', err);
      currentCleanup = null;
    }

    // Find matching route
    for (const r of routes) {
      const match = path.match(r.regex);
      if (match) {
        const params = {};
        r.paramNames.forEach((name, i) => {
          params[name] = decodeURIComponent(match[i + 1]);
        });

        try {
          const view = r.handler(params);
          currentView = view;

          const contentEl = document.getElementById('content');
          if (contentEl) {
            const result = view.render();
            if (typeof result === 'string') {
              contentEl.innerHTML = result;
            } else if (result instanceof HTMLElement) {
              contentEl.innerHTML = '';
              contentEl.appendChild(result);
            }

            // Add entrance animation
            const inner = contentEl.querySelector('.content__inner');
            if (inner) {
              inner.classList.add('view-enter');
            }

            // Call mount after DOM is ready
            if (view.mount) {
              requestAnimationFrame(() => {
                try {
                  view.mount();
                } catch (err) {
                  console.error('[Router] Error in mount:', err);
                }
              });
            }

            if (view.cleanup) {
              currentCleanup = view.cleanup;
            }
          } else {
            console.error('[Router] #content element not found');
          }
        } catch (err) {
          console.error('[Router] Error rendering route:', path, err);
        }

        // Update sidebar active state
        updateSidebarActive(path);
        return;
      }
    }

    // No route matched — redirect to login
    console.warn('[Router] No route matched for:', path, '→ redirecting to /login');
    navigate('/login');
  };

  window.addEventListener('hashchange', () => {
    console.log('[Router] hashchange event fired, hash:', window.location.hash);
    handleRoute();
  });

  console.log('[Router] Starting router, initial render');
  handleRoute(); // Initial render
}

/**
 * Update sidebar link highlighting
 */
function updateSidebarActive(path) {
  document.querySelectorAll('.sidebar__link').forEach(link => {
    const href = link.getAttribute('data-route');
    if (!href) return;

    const isActive = path === href || (href !== '/login' && path.startsWith(href));
    link.classList.toggle('sidebar__link--active', isActive);
  });
}
