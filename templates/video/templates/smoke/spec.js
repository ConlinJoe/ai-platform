export default {
  title: 'Synthetic smoke',
  fps: 10,
  duration: 0.5,
  format: 'landscape',
  width: 640,
  height: 360,
  audio: null,
  brand: {
    name: 'Sample',
    ink: '#111111',
    paper: '#f4f1ea',
    accent: '#c4552a',
    sans: 'system-ui, sans-serif',
    logo: null,
  },
  scenes: [
    { id: 'mark', at: 0, dur: 0.5, kind: 'mark', transition: 'none', lines: ['SAMPLE'] },
  ],
};
