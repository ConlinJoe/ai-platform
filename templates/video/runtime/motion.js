// Original stage for harness video campaigns.
// A frame is a pure function of the spec and the time in seconds.
// This file is not the Scenario Kinetic Film engine.

export function clamp01(value) {
  return Math.min(1, Math.max(0, value));
}

export function easeOut(value) {
  const t = clamp01(value);
  return 1 - (1 - t) * (1 - t) * (1 - t);
}

export function easeInOut(value) {
  const t = clamp01(value);
  return t < 0.5 ? 2 * t * t : 1 - ((-2 * t + 2) ** 2) / 2;
}

function metrics(spec) {
  const w = spec.width;
  const h = spec.height;
  const portrait = h > w;
  const margin = Math.round(w * (portrait ? 0.08 : 0.072));
  const headline = Math.round((portrait ? w : h) * 0.084);
  return {
    w,
    h,
    portrait,
    margin,
    headline,
    support: Math.round(headline * 0.42),
    gap: Math.round(headline * 0.18),
  };
}

function layer(box) {
  const node = document.createElement('div');
  node.style.position = 'absolute';
  node.style.left = '0';
  node.style.top = '0';
  node.style.width = box.w + 'px';
  node.style.height = box.h + 'px';
  node.style.overflow = 'hidden';
  return node;
}

function activeIndex(scenes, time) {
  let index = 0;
  for (let i = 0; i < scenes.length; i += 1) {
    if (time + 0.0001 >= scenes[i].at) index = i;
  }
  return index;
}

function textBlock(parent, lines, box, reveal, options) {
  const left = options.left != null ? options.left : box.margin;
  const width = options.width != null ? options.width : box.w - left - box.margin;
  const stack = document.createElement('div');
  stack.style.position = 'absolute';
  stack.style.left = left + 'px';
  stack.style.width = width + 'px';
  stack.style.display = 'flex';
  stack.style.flexDirection = 'column';
  stack.style.gap = box.gap + 'px';
  if (options.bottom != null) {
    stack.style.bottom = options.bottom + 'px';
  } else {
    stack.style.top = (options.top != null ? options.top : box.margin) + 'px';
  }
  lines.forEach((line, index) => {
    const mask = document.createElement('div');
    mask.style.overflow = 'hidden';
    const row = document.createElement('div');
    row.textContent = line;
    row.style.fontFamily = 'inherit';
    row.style.fontWeight = options.weight || '560';
    row.style.fontSize = (options.size || box.headline) + 'px';
    row.style.lineHeight = '0.96';
    row.style.letterSpacing = '-0.035em';
    row.style.color = options.color;
    const words = options.words ? String(line).split(' ') : [line];
    if (options.words) {
      row.textContent = '';
      words.forEach((word, wordIndex) => {
        const piece = document.createElement('span');
        piece.textContent = word;
        piece.style.display = 'inline-block';
        const local = clamp01((reveal - (index * 0.08 + wordIndex * 0.06)) / 0.55);
        const eased = easeOut(local);
        piece.style.transform = 'translateY(' + ((1 - eased) * 110) + '%)';
        piece.style.marginRight = '0.28em';
        row.appendChild(piece);
      });
    } else {
      const local = clamp01((reveal - index * 0.08) / 0.62);
      const eased = easeOut(local);
      row.style.transform = 'translateY(' + ((1 - eased) * 110) + '%)';
    }
    mask.appendChild(row);
    stack.appendChild(mask);
  });
  parent.appendChild(stack);
}

function mediaWell(parent, scene, box, spec) {
  const well = document.createElement('div');
  well.style.position = 'absolute';
  well.style.overflow = 'hidden';
  well.style.background = spec.brand.accent;
  if (box.portrait) {
    well.style.left = '0';
    well.style.top = '0';
    well.style.width = box.w + 'px';
    well.style.height = Math.round(box.h * 0.58) + 'px';
  } else {
    well.style.left = '0';
    well.style.top = '0';
    well.style.width = Math.round(box.w * 0.58) + 'px';
    well.style.height = box.h + 'px';
  }
  if (scene.image) {
    const image = document.createElement('img');
    image.src = scene.image;
    image.alt = '';
    image.style.width = '100%';
    image.style.height = '100%';
    image.style.objectFit = 'cover';
    image.style.objectPosition = scene.focus || 'center';
    well.appendChild(image);
  } else {
    const block = document.createElement('div');
    block.style.position = 'absolute';
    block.style.left = '12%';
    block.style.right = '18%';
    block.style.top = '18%';
    block.style.bottom = '22%';
    block.style.background = spec.brand.ink;
    well.appendChild(block);
  }
  parent.appendChild(well);
  return well;
}

function paintScene(parent, spec, scene, time, box, reveal) {
  const brand = spec.brand;
  const kind = scene.kind;
  parent.style.background = kind === 'panel' || kind === 'hero' ? brand.ink : brand.paper;
  parent.style.color = kind === 'panel' || kind === 'hero' ? brand.paper : brand.ink;

  if (kind === 'mark') {
    parent.style.background = brand.paper;
    const travel = clamp01(time / Math.max(spec.duration, 0.001));
    const dot = document.createElement('div');
    const size = Math.round(box.h * 0.28);
    dot.style.position = 'absolute';
    dot.style.width = size + 'px';
    dot.style.height = size + 'px';
    dot.style.borderRadius = '50%';
    dot.style.background = brand.accent;
    dot.style.left = Math.round(box.margin + travel * box.w * 0.12) + 'px';
    dot.style.top = Math.round(box.h * 0.28) + 'px';
    parent.appendChild(dot);
    textBlock(parent, scene.lines, box, 1, {
      color: brand.ink,
      top: Math.round(box.h * 0.62),
      size: box.headline,
    });
    return;
  }

  if (kind === 'hero') {
    const well = document.createElement('div');
    well.style.position = 'absolute';
    well.style.inset = '0';
    well.style.overflow = 'hidden';
    well.style.background = brand.accent;
    const scale = 1.06 - 0.06 * clamp01(time / spec.duration);
    if (scene.image) {
      const image = document.createElement('img');
      image.src = scene.image;
      image.alt = '';
      image.style.width = '100%';
      image.style.height = '100%';
      image.style.objectFit = 'cover';
      image.style.objectPosition = scene.focus || 'center';
      image.style.transform = 'scale(' + scale + ')';
      image.style.transformOrigin = 'center';
      well.appendChild(image);
    } else {
      well.style.transform = 'scale(' + scale + ')';
      well.style.transformOrigin = 'center';
      const slab = document.createElement('div');
      slab.style.position = 'absolute';
      slab.style.left = '8%';
      slab.style.right = '28%';
      slab.style.top = '10%';
      slab.style.bottom = '24%';
      slab.style.background = brand.ink;
      well.appendChild(slab);
    }
    parent.appendChild(well);
    const scrim = document.createElement('div');
    scrim.style.position = 'absolute';
    scrim.style.left = '0';
    scrim.style.right = '0';
    scrim.style.bottom = '0';
    scrim.style.height = (box.portrait ? '46%' : '42%');
    scrim.style.background = 'linear-gradient(to top, rgba(0,0,0,0.55), rgba(0,0,0,0))';
    parent.appendChild(scrim);
    textBlock(parent, scene.lines, box, reveal, {
      color: '#f7f4ee',
      bottom: box.margin,
      size: Math.round(box.headline * 0.92),
    });
    return;
  }

  if (kind === 'panel') {
    mediaWell(parent, scene, box, spec);
    const side = box.portrait
      ? { top: Math.round(box.h * 0.64), size: Math.round(box.headline * 0.72) }
      : { top: Math.round(box.h * 0.36), size: Math.round(box.headline * 0.62) };
    if (!box.portrait) {
      const copy = document.createElement('div');
      copy.style.position = 'absolute';
      copy.style.left = Math.round(box.w * 0.58) + 'px';
      copy.style.top = '0';
      copy.style.width = Math.round(box.w * 0.42) + 'px';
      copy.style.height = box.h + 'px';
      copy.style.background = brand.paper;
      parent.appendChild(copy);
    }
    textBlock(parent, scene.lines, box, reveal, {
      color: box.portrait ? brand.paper : brand.ink,
      top: side.top,
      size: side.size,
      left: box.portrait ? box.margin : Math.round(box.w * 0.62),
      width: box.portrait ? box.w - box.margin * 2 : Math.round(box.w * 0.32),
      words: scene.choreography === 'words',
    });
    return;
  }

  if (kind === 'identity') {
    parent.style.background = brand.ink;
    const rule = document.createElement('div');
    const width = Math.round((box.w - box.margin * 2) * easeOut(reveal));
    rule.style.position = 'absolute';
    rule.style.left = box.margin + 'px';
    rule.style.top = Math.round(box.h * 0.42) + 'px';
    rule.style.height = '2px';
    rule.style.width = width + 'px';
    rule.style.background = brand.accent;
    parent.appendChild(rule);
    textBlock(parent, scene.lines, box, reveal, {
      color: brand.paper,
      top: Math.round(box.h * 0.46),
      size: Math.round(box.headline * 1.15),
    });
    return;
  }

  if (kind === 'end') {
    parent.style.background = brand.ink;
    const logoSrc = scene.logo || brand.logo;
    if (logoSrc) {
      const logo = document.createElement('img');
      logo.src = logoSrc;
      logo.alt = '';
      const logoHeight = Math.round(box.h * 0.12);
      logo.style.position = 'absolute';
      logo.style.left = box.margin + 'px';
      logo.style.top = box.margin + 'px';
      logo.style.height = logoHeight + 'px';
      logo.style.width = 'auto';
      logo.style.maxWidth = Math.round(box.w * 0.46) + 'px';
      logo.style.objectFit = 'contain';
      parent.appendChild(logo);
    }
    textBlock(parent, scene.lines, box, reveal, {
      color: brand.paper,
      top: Math.round(box.h * (box.portrait ? 0.62 : 0.58)),
      size: Math.round(box.headline * 0.7),
    });
    return;
  }

  textBlock(parent, scene.lines || [], box, reveal, {
    color: brand.ink,
    top: box.portrait ? Math.round(box.h * 0.34) : Math.round(box.h * 0.36),
    words: scene.choreography === 'words',
  });
}

function transitionLayer(box, spec, scene, time, reveal, mode, progress) {
  const incoming = layer(box);
  paintScene(incoming, spec, scene, time, box, reveal);
  if (mode === 'wipe' || mode === 'slats') {
    const open = easeInOut(progress);
    incoming.style.clipPath = 'inset(0 ' + ((1 - open) * 100) + '% 0 0)';
  }
  return incoming;
}

function slatRules(box, progress, color) {
  const host = layer(box);
  const edge = easeInOut(progress) * box.w;
  const count = 8;
  for (let i = 0; i < count; i += 1) {
    const rule = document.createElement('div');
    rule.style.position = 'absolute';
    rule.style.left = '0';
    rule.style.top = (((i + 0.5) / count) * box.h) + 'px';
    rule.style.height = '2px';
    rule.style.width = edge + 'px';
    rule.style.background = color;
    host.appendChild(rule);
  }
  return host;
}

export function drawFilm(stage, spec, time) {
  const box = metrics(spec);
  const scenes = spec.scenes || [];
  stage.replaceChildren();
  stage.style.width = box.w + 'px';
  stage.style.height = box.h + 'px';
  stage.style.position = 'relative';
  stage.style.overflow = 'hidden';
  stage.style.background = spec.brand.ink;
  stage.style.fontFamily = spec.brand.sans || 'sans-serif';
  if (!scenes.length) return;

  const index = activeIndex(scenes, time);
  const scene = scenes[index];
  const next = scenes[index + 1];
  const mode = scene.transition || 'none';
  const lead = 0.5;
  let progress = 0;
  if (next && mode !== 'none' && time >= next.at - lead && time < next.at) {
    progress = (time - (next.at - lead)) / lead;
  }

  const current = layer(box);
  const reveal = progress > 0 ? 1 : clamp01((time - scene.at) / 0.7);
  paintScene(current, spec, scene, time, box, reveal);
  stage.appendChild(current);

  if (progress > 0 && next) {
    const incomingReveal = clamp01(progress / 0.85);
    stage.appendChild(transitionLayer(box, spec, next, time, incomingReveal, mode, progress));
    if (mode === 'slats') {
      stage.appendChild(slatRules(box, progress, spec.brand.paper));
    }
  }
}
