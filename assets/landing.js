(function () {
  const cfg = window.PIKOPE_LANDING || { apiBase: 'https://adminnew.pikope.com', defaultLang: 'bn' };
  const GRID_IDS = ['grid-img-0', 'grid-img-1', 'grid-img-2', 'grid-img-3'];
  const GRID_FALLBACK = [
    'https://i.ibb.co.com/3YpmVd3m/Screenshot-20261021-040654.jpg',
    'https://i.ibb.co.com/cKMM52z9/Screenshot-20261021-040705.jpg',
    'https://i.ibb.co.com/7xHGT0mg/Screenshot-20261021-040717.jpg',
    'https://i.ibb.co.com/ZwwYXNG/Screenshot-20261021-040819.jpg',
  ];
  const PICO_IMG_FALLBACK = 'https://i.ibb.co.com/JJt16vH/auto-payments-f9dfa769.png';

  function $(id) {
    return document.getElementById(id);
  }

  function setDownload(url, labelBn, labelEn) {
    const btn = $('download-btn');
    const hint = $('download-hint');
    if (!btn) return;
    const labels = document.querySelectorAll('#download-btn .lang-bn, #download-btn .lang-en');
    if (labelBn && labels[0]) labels[0].textContent = labelBn;
    if (labelEn && labels[1]) labels[1].textContent = labelEn;
    if (url) {
      btn.href = url;
      btn.setAttribute('download', '');
      btn.removeAttribute('aria-disabled');
      btn.classList.remove('opacity-60', 'pointer-events-none');
      if (hint) hint.classList.add('hidden');
    } else {
      btn.href = '#';
      btn.classList.add('opacity-60', 'pointer-events-none');
      btn.setAttribute('aria-disabled', 'true');
      if (hint) hint.classList.remove('hidden');
    }
  }

  function applyScreenshots(urls) {
    GRID_IDS.forEach((id, i) => {
      const el = $(id);
      if (!el) return;
      const u = urls && urls[i] ? urls[i] : GRID_FALLBACK[i];
      if (u) el.src = u;
    });
    const pico = $('pico-promo-img');
    if (pico && urls && urls[4] && !pico.dataset.heroSet) pico.src = urls[4];
  }

  function applyStats(stats) {
    if (!stats) return;
    const rating = $('stat-rating-big');
    if (rating && stats.rating) rating.textContent = stats.rating;
    const rev = $('stat-reviews-label');
    if (rev && stats.reviews) rev.textContent = stats.reviews;
  }

  async function loadAdmin() {
    const base = (cfg.apiBase || '').replace(/\/$/, '');
    try {
      const res = await fetch(base + '/landing/public', { cache: 'no-store' });
      if (!res.ok) throw new Error('HTTP ' + res.status);
      const data = await res.json();
      const lang = cfg.defaultLang === 'en' ? 'en' : 'bn';
      const loc = (data.locales && data.locales[lang]) || {};
      setDownload(data.apkUrl || cfg.fallbackApk || '', loc.apkLabel, data.locales?.en?.apkLabel);
      applyScreenshots(data.screenshots || []);
      if (data.heroImageUrl) {
        const pico = $('pico-promo-img');
        if (pico) {
          pico.src = data.heroImageUrl;
          pico.dataset.heroSet = '1';
        }
      }
      applyStats(data.stats);
      if (typeof setLanguage === 'function') {
        setLanguage(data.defaultLang === 'en' ? 'en' : 'bn');
      }
    } catch (e) {
      console.warn('[PikoPe landing]', e);
      setDownload(cfg.fallbackApk || '', 'PikoPe অ্যাপ ডাউনলোড', 'Download PikoPe App');
      applyScreenshots([]);
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    const pico = $('pico-promo-img');
    if (pico && !pico.getAttribute('src')) pico.src = PICO_IMG_FALLBACK;
    loadAdmin();
  });
})();
