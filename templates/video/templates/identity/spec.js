export default {
  title: 'Brand identity reveal',
  fps: 30,
  duration: 8,
  format: 'landscape',
  width: 1920,
  height: 1080,
  audio: null,
  brand: {
    name: 'Brand',
    ink: '#121212',
    paper: '#f3efe6',
    accent: '#c4a15a',
    sans: 'Avenir Next, Segoe UI, sans-serif',
    logo: null,
  },
  scenes: [
    { id: 'mark', at: 0, dur: 8, kind: 'identity', transition: 'none', lines: ['Brand', 'The line under the name.'] },
  ],
};
