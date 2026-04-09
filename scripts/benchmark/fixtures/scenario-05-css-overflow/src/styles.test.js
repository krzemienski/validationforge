// Unit tests for CSS overflow utilities
// NOTE: This file exists because the team relied on unit tests instead of
// real ValidationForge validation journeys.

const { measureContainer, applyEllipsis } = require('./app');

describe('measureContainer', () => {
  it('detects overflow when scrollWidth > clientWidth', () => {
    const el = { scrollWidth: 300, clientWidth: 200, offsetHeight: 50 };
    const result = measureContainer(el);
    expect(result.overflows).toBe(true);
    expect(result.height).toBe(50);
  });

  it('reports no overflow when scrollWidth <= clientWidth', () => {
    const el = { scrollWidth: 100, clientWidth: 200, offsetHeight: 40 };
    const result = measureContainer(el);
    expect(result.overflows).toBe(false);
  });
});

describe('applyEllipsis', () => {
  it('applies overflow styles when container overflows', () => {
    const el = { scrollWidth: 500, clientWidth: 200, offsetHeight: 20 };
    const updated = applyEllipsis(el);
    expect(updated.style.overflow).toBe('hidden');
    expect(updated.style.textOverflow).toBe('ellipsis');
  });

  it('returns element unchanged when no overflow', () => {
    const el = { scrollWidth: 100, clientWidth: 300, offsetHeight: 20, style: {} };
    const updated = applyEllipsis(el);
    expect(updated.style.overflow).toBeUndefined();
  });
});
