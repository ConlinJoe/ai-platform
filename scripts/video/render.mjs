// Local frame renderer for a harness video campaign.
// Uses the system Google Chrome through Playwright. It does not call Scenario.
import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import http from 'node:http';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
  '.woff2': 'font/woff2',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
};

function fail(message) {
  console.error(message);
  process.exit(1);
}

function pngSize(buffer) {
  if (buffer.length < 24 || buffer.toString('ascii', 12, 16) !== 'IHDR') {
    return null;
  }
  return { width: buffer.readUInt32BE(16), height: buffer.readUInt32BE(20) };
}

function serve(root) {
  const server = http.createServer((request, response) => {
    const url = new URL(request.url || '/', 'http://127.0.0.1');
    let rel = decodeURIComponent(url.pathname);
    if (rel.endsWith('/')) rel += 'index.html';
    const file = path.resolve(root, '.' + rel);
    if (!file.startsWith(root + path.sep) && file !== root) {
      response.writeHead(403);
      response.end();
      return;
    }
    fs.readFile(file, (error, data) => {
      if (error) {
        response.writeHead(404);
        response.end();
        return;
      }
      response.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
      response.end(data);
    });
  });
  return new Promise((resolve) => {
    server.listen(0, '127.0.0.1', () => resolve(server));
  });
}

function levelFor(width, height) {
  return width * height > 2228224 ? '5.1' : '4.2';
}

function workerChoice(memoryGb, cpus, fourK) {
  const perWorker = fourK ? 8 : 4;
  const byMemory = Math.floor(memoryGb / perWorker);
  const byCpu = Math.floor(cpus / 4);
  const available = Math.max(1, Math.min(2, byMemory, byCpu || 1));
  return { available, used: 1 };
}

function ffmpeg(args) {
  return new Promise((resolve, reject) => {
    const child = spawn('ffmpeg', args, { stdio: ['ignore', 'inherit', 'pipe'] });
    let errorText = '';
    child.stderr.on('data', (chunk) => {
      errorText += chunk.toString();
    });
    child.on('error', reject);
    child.on('close', (code) => {
      if (code === 0) resolve();
      else reject(new Error(errorText.trim() || `ffmpeg exited ${code}`));
    });
  });
}

async function main() {
  const campaign = path.resolve(process.argv[2] || '');
  const replace = process.argv.includes('--replace');
  const resolution = process.argv.includes('--resolution')
    ? process.argv[process.argv.indexOf('--resolution') + 1]
    : '1080';
  if (!campaign || !fs.existsSync(path.join(campaign, 'film', 'index.html'))) {
    fail('Usage: render.mjs <campaign-dir> [--replace] [--resolution 1080|4k]');
  }
  if (!['1080', '4k'].includes(resolution)) fail('Resolution must be 1080 or 4k.');
  if (!fs.existsSync(path.join(campaign, 'film', 'spec.js'))) fail('Campaign is missing film/spec.js.');

  const memoryGb = os.totalmem() / (1024 ** 3);
  const cpus = os.cpus().length;
  const fourK = resolution === '4k';
  if (fourK && memoryGb < 12) {
    fail(`4K needs at least 12 GB of memory. This machine reports ${memoryGb.toFixed(1)} GB. Render the 1080 master instead.`);
  }
  const workers = workerChoice(memoryGb, cpus, fourK);
  const dsf = fourK ? 2 : 1;
  console.log(`Local render. No Scenario credits. ${workers.used} worker (${workers.available} available), ${memoryGb.toFixed(0)} GB memory, ${cpus} CPUs.`);

  const specUrl = pathToFileURL(path.join(campaign, 'film', 'spec.js')).href;
  const spec = (await import(specUrl)).default;
  const frames = Math.round(spec.duration * spec.fps);
  const cssWidth = spec.width;
  const cssHeight = spec.height;
  const outWidth = cssWidth * dsf;
  const outHeight = cssHeight * dsf;
  const level = levelFor(outWidth, outHeight);
  const slug = path.basename(campaign);
  const masters = path.join(campaign, 'renders', 'masters');
  const reviewDir = path.join(campaign, 'renders', 'review');
  const stills = path.join(campaign, 'renders', 'stills');
  const master = path.join(masters, `${slug}-${outWidth}x${outHeight}-${spec.fps}.mp4`);
  const review = path.join(reviewDir, `${slug}-review.mp4`);
  if (fs.existsSync(master) && !replace) {
    fail(`Master already exists: ${master}\nRe-run with --replace to write a new master. Existing files were left in place.`);
  }
  fs.mkdirSync(masters, { recursive: true });
  fs.mkdirSync(reviewDir, { recursive: true });
  fs.mkdirSync(stills, { recursive: true });

  const runtime = path.resolve(campaign, '..', '..', '.runtime');
  const require = createRequire(path.join(runtime, 'package.json'));
  const { chromium } = require('playwright');
  const server = await serve(campaign);
  const port = server.address().port;
  const pageUrl = `http://127.0.0.1:${port}/film/index.html?render=1`;
  const partial = master + '.partial.mp4';
  const allowBrowserDownload = process.env.VIDEO_ALLOW_PLAYWRIGHT_BROWSER === '1';
  let browser;
  try {
    browser = await chromium.launch({
      headless: true,
      channel: allowBrowserDownload ? undefined : 'chrome',
      args: ['--disable-dev-shm-usage', '--hide-scrollbars'],
    });
  } catch (error) {
    server.close();
    if (!allowBrowserDownload) {
      fail(`Could not launch Google Chrome (${error.message}). Local rendering uses the installed Chrome and does not download a browser. Set VIDEO_ALLOW_PLAYWRIGHT_BROWSER=1 only when you want Playwright to download Chromium.`);
    }
    fail(`Could not launch a browser (${error.message}).`);
  }

  const context = await browser.newContext({
    viewport: { width: cssWidth, height: cssHeight },
    deviceScaleFactor: dsf,
  });
  const page = await context.newPage();
  const encoder = spawn('ffmpeg', [
    '-y', '-v', 'error',
    '-f', 'image2pipe', '-vcodec', 'png', '-framerate', String(spec.fps),
    '-i', 'pipe:0',
    '-an',
    '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-profile:v', 'high',
    '-crf', process.env.VIDEO_X264_CRF || '16',
    '-preset', process.env.VIDEO_X264_PRESET || 'medium',
    '-level', level,
    '-x264-params', 'colorprim=bt709:transfer=bt709:colormatrix=bt709',
    '-color_primaries', 'bt709', '-color_trc', 'bt709', '-colorspace', 'bt709',
    '-color_range', 'tv',
    '-movflags', '+faststart',
    partial,
  ], { stdio: ['pipe', 'inherit', 'pipe'] });
  let encoderError = '';
  encoder.stderr.on('data', (chunk) => {
    encoderError += chunk.toString();
  });

  try {
    await page.goto(pageUrl, { waitUntil: 'load' });
    await page.waitForFunction(() => window.__videoReady === true, null, { timeout: 20000 });
    const info = await page.evaluate(() => window.__videoInfo);
    if (info.width !== cssWidth || info.height !== cssHeight) {
      throw new Error(`Film reported ${info.width}x${info.height}, spec says ${cssWidth}x${cssHeight}.`);
    }
    for (let frame = 0; frame < frames; frame += 1) {
      const time = frame / spec.fps;
      await page.evaluate((value) => window.__videoSeek(value), time);
      const buffer = await page.screenshot({ type: 'png' });
      if (frame === 0) {
        const size = pngSize(buffer);
        if (!size || size.width !== outWidth || size.height !== outHeight) {
          throw new Error(`First frame is ${size ? `${size.width}x${size.height}` : 'unreadable'}, expected ${outWidth}x${outHeight}.`);
        }
      }
      const ready = encoder.stdin.write(buffer);
      if (!ready) await new Promise((resolve) => encoder.stdin.once('drain', resolve));
    }
    encoder.stdin.end();
    const code = await new Promise((resolve) => encoder.on('close', resolve));
    if (code !== 0) throw new Error(encoderError.trim() || `encoder exited ${code}`);
    fs.renameSync(partial, master);

    if (spec.audio) {
      const audioPath = path.resolve(campaign, spec.audio);
      if (!fs.existsSync(audioPath)) throw new Error(`Audio file is missing: ${audioPath}`);
      const muxed = master + '.audio.mp4';
      await ffmpeg([
        '-y', '-v', 'error', '-i', master, '-i', audioPath,
        '-map', '0:v:0', '-map', '1:a:0', '-c:v', 'copy', '-c:a', 'aac', '-b:a', '192k',
        '-t', String(spec.duration), '-movflags', '+faststart', muxed,
      ]);
      fs.renameSync(muxed, master);
    }

    const reviewAudio = spec.audio ? ['-c:a', 'aac', '-b:a', '160k'] : ['-an'];
    await ffmpeg([
      '-y', '-v', 'error', '-i', master,
      ...reviewAudio, '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-profile:v', 'high',
      '-crf', '28', '-preset', 'veryfast', '-level', level,
      '-x264-params', 'colorprim=bt709:transfer=bt709:colormatrix=bt709',
      '-color_primaries', 'bt709', '-color_trc', 'bt709', '-colorspace', 'bt709',
      '-color_range', 'tv', '-movflags', '+faststart', review,
    ]);

    const stamps = [0, 0.25, 0.5, 0.75, 0.92].map((share, index) => ({
      index,
      time: Math.min(spec.duration - 1 / spec.fps, spec.duration * share),
    }));
    const stillPaths = [];
    for (const stamp of stamps) {
      const still = path.join(stills, `frame-${String(stamp.index + 1).padStart(2, '0')}.png`);
      await ffmpeg(['-y', '-v', 'error', '-ss', stamp.time.toFixed(3), '-i', master, '-frames:v', '1', still]);
      stillPaths.push(still);
    }
    const tileInputs = stillPaths.flatMap((still) => ['-i', still]);
    const pads = stillPaths.map((_, index) => `[${index}:v]`).join('');
    await ffmpeg([
      '-y', '-v', 'error', ...tileInputs,
      '-filter_complex', `${pads}hstack=inputs=${stillPaths.length}`,
      path.join(campaign, 'renders', 'contact-sheet.jpg'),
    ]);

    const report = path.join(campaign, 'renders', 'technical-report.json');
    const validator = path.join(path.dirname(fileURLToPath(import.meta.url)), 'validate.py');
    const result = spawn(process.env.PYTHON || 'python3', [
      validator,
      '--video', master,
      '--expect-width', String(outWidth),
      '--expect-height', String(outHeight),
      '--expect-fps', String(spec.fps),
      '--expect-frames', String(frames),
      '--expect-audio', spec.audio ? 'yes' : 'no',
      '--report', report,
    ], { stdio: 'inherit' });
    const status = await new Promise((resolve) => result.on('close', resolve));
    console.log(master);
    console.log(review);
    if (status !== 0) throw new Error('Technical validation failed.');
  } catch (error) {
    try { encoder.kill('SIGTERM'); } catch { /* encoder already closed */ }
    if (fs.existsSync(partial)) fs.rmSync(partial, { force: true });
    throw error;
  } finally {
    await browser.close();
    server.close();
  }
}

main().catch((error) => fail(error.message || String(error)));
