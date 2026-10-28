export default {
  title: 'Fifteen second vertical advertisement',
  fps: 30,
  duration: 15,
  format: 'vertical',
  width: 1080,
  height: 1920,
  audio: null,
  brand: {
    name: 'Brand',
    ink: '#161616',
    paper: '#f3f0e8',
    accent: '#1e4d3a',
    sans: 'Avenir Next, Segoe UI, sans-serif',
    logo: null,
  },
  scenes: [
    { id: 'hook', at: 0, dur: 3.6, kind: 'type', transition: 'slats', choreography: 'words', lines: ['Say the thing', 'that matters.'] },
    { id: 'proof', at: 3.6, dur: 4.2, kind: 'panel', transition: 'wipe', lines: ['Show the real object.'], image: null },
    { id: 'offer', at: 7.8, dur: 3.4, kind: 'type', transition: 'slats', lines: ['Make the offer', 'in one breath.'] },
    { id: 'end', at: 11.2, dur: 3.8, kind: 'end', transition: 'none', lines: ['Brand', 'Take the next step.'] },
  ],
};
