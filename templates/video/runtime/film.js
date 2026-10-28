// Campaign playback page. Edit spec.js for words, timing, and brand.
// Replace this file only when the campaign needs motion the shared stage
// does not express. Every frame is a pure function of time.
import spec from './spec.js';
import { drawFilm } from './motion.js';

const stage = document.getElementById('stage');
document.title = spec.title;

function seek(time) {
  const end = Math.max(0, spec.duration - 1 / spec.fps);
  const t = Math.min(Math.max(time, 0), end);
  drawFilm(stage, spec, t);
}

function sources(value) {
  const found = [];
  for (const scene of value.scenes || []) {
    if (scene.image) found.push(scene.image);
    if (scene.logo) found.push(scene.logo);
  }
  if (value.brand && value.brand.logo) found.push(value.brand.logo);
  return found;
}

function loadImage(src) {
  const image = new Image();
  image.src = src;
  return image.decode().then(() => image);
}

async function boot() {
  const images = sources(spec);
  if (images.length) {
    await Promise.all(images.map(loadImage));
  }
  if (document.fonts && document.fonts.ready) {
    await document.fonts.ready;
  }
  window.__videoInfo = {
    title: spec.title,
    fps: spec.fps,
    duration: spec.duration,
    width: spec.width,
    height: spec.height,
    format: spec.format,
    audio: spec.audio || null,
  };
  window.__videoSeek = seek;
  seek(0);
  window.__videoReady = true;
  if (!new URLSearchParams(location.search).has('render')) {
    mountPreview();
  }
}

function mountPreview() {
  const fps = spec.fps;
  const end = Math.max(0, spec.duration - 1 / fps);
  let time = Number(new URLSearchParams(location.search).get('t') || 0);
  let playing = false;
  let last = 0;
  const bar = document.createElement('input');
  bar.type = 'range';
  bar.min = '0';
  bar.max = String(end);
  bar.step = String(1 / fps);
  bar.value = String(time);
  bar.style.position = 'fixed';
  bar.style.left = '16px';
  bar.style.right = '140px';
  bar.style.bottom = '12px';
  bar.style.zIndex = '5';
  const label = document.createElement('div');
  label.style.position = 'fixed';
  label.style.right = '16px';
  label.style.bottom = '12px';
  label.style.color = '#fff';
  label.style.font = '14px system-ui, sans-serif';
  label.style.zIndex = '5';
  document.body.append(bar, label);
  const show = () => {
    seek(time);
    bar.value = String(time);
    label.textContent = time.toFixed(2) + ' s';
  };
  bar.addEventListener('input', () => {
    time = Number(bar.value);
    show();
  });
  addEventListener('keydown', (event) => {
    if (event.code === 'Space') {
      playing = !playing;
      last = performance.now();
      event.preventDefault();
    }
    if (event.code === 'ArrowRight') {
      time = Math.min(end, time + 1 / fps);
      show();
    }
    if (event.code === 'ArrowLeft') {
      time = Math.max(0, time - 1 / fps);
      show();
    }
  });
  const loop = (now) => {
    if (playing) {
      time += (now - last) / 1000;
      if (time > end) time = 0;
      show();
    }
    last = now;
    requestAnimationFrame(loop);
  };
  requestAnimationFrame(loop);
  show();
}

boot().catch((error) => {
  document.body.textContent = error && error.message ? error.message : String(error);
  throw error;
});
