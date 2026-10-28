export default {
  title: 'Product announcement',
  fps: 30,
  duration: 12,
  format: 'landscape',
  width: 1920,
  height: 1080,
  audio: null,
  brand: {
    name: 'Brand',
    ink: '#171717',
    paper: '#f6f3ec',
    accent: '#8c3d2f',
    sans: 'Avenir Next, Segoe UI, sans-serif',
    logo: null,
  },
  scenes: [
    { id: 'open', at: 0, dur: 3.2, kind: 'type', transition: 'wipe', lines: ['Something new', 'is ready.'] },
    { id: 'what', at: 3.2, dur: 3.2, kind: 'type', transition: 'wipe', lines: ['Say what it is.', 'Leave the rest out.'] },
    { id: 'when', at: 6.4, dur: 2.6, kind: 'type', transition: 'wipe', lines: ['Name the moment.'] },
    { id: 'end', at: 9, dur: 3, kind: 'end', transition: 'none', lines: ['Brand', 'Where to go next.'] },
  ],
};
