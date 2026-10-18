// Service Worker Bibit Pusaka - Offline & PWA Multi-Outlet Support
// Developed by I Gusti Ngurah Aristiana Adi Putra

const CACHE_NAME = 'bibitpusaka-v2.0';
const STATIC_ASSETS = [
  './',
  './index.html',
  './portal.html',
  './paspor.html',
  './tanaman.html',
  './manifest.json',
  './icon-192.svg',
  './icon-512.svg',
  'https://cdn.tailwindcss.com',
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2',
  'https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js',
  'https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js',
  'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css',
  'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return Promise.allSettled(
        STATIC_ASSETS.map((url) =>
          cache.add(url).catch((err) => {
            console.warn(`[SW] Gagal precache aset: ${url}`, err);
          })
        )
      );
    })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            console.log(`[SW] Menghapus cache lama: ${key}`);
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Strategi Network-First with Cache Fallback
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const url = new URL(event.request.url);

  // Jangan cache panggilan realtime/websocket dan autentikasi Supabase
  if (url.pathname.includes('/realtime/v1/') || url.pathname.includes('/auth/v1/')) {
    return;
  }

  event.respondWith(
    fetch(event.request)
      .then((networkResponse) => {
        if (networkResponse && networkResponse.status === 200 && (url.protocol === 'http:' || url.protocol === 'https:')) {
          const responseToCache = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseToCache);
          });
        }
        return networkResponse;
      })
      .catch(async () => {
        // Fallback saat offline
        const cachedResponse = await caches.match(event.request);
        if (cachedResponse) {
          return cachedResponse;
        }

        // Navigasi routing halaman saat offline
        if (event.request.mode === 'navigate') {
          if (url.pathname.endsWith('portal.html')) {
            const portalCache = await caches.match('./portal.html');
            if (portalCache) return portalCache;
          }
          if (url.pathname.endsWith('tanaman.html')) {
            const tanamCache = await caches.match('./tanaman.html');
            if (tanamCache) return tanamCache;
          }
          if (url.pathname.endsWith('paspor.html')) {
            const pasporCache = await caches.match('./paspor.html');
            if (pasporCache) return pasporCache;
          }
          const defaultHtml = await caches.match('./index.html');
          if (defaultHtml) return defaultHtml;
        }

        return new Response('Koneksi offline dan data belum tersimpan di cache lokal.', {
          status: 503,
          statusText: 'Service Unavailable (Offline)',
          headers: new Headers({ 'Content-Type': 'text/plain; charset=utf-8' })
        });
      })
  );
});
