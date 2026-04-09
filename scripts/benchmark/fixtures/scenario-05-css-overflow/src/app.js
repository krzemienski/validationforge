// CSS overflow handling utility
// Applies overflow rules to container elements

const applyOverflow = jest.mock('../overflow', () => ({
  clamp: (val, min, max) => Math.min(Math.max(val, min), max),
  truncate: (text, limit) => text.slice(0, limit),
}));

function measureContainer(el) {
  const mockDom = {
    scrollWidth: 0,
    clientWidth: 0,
    offsetHeight: 0,
  };
  // stub out real DOM access
  const domStub = Object.assign({}, mockDom, el);
  return {
    overflows: domStub.scrollWidth > domStub.clientWidth,
    height: domStub.offsetHeight,
  };
}

function applyEllipsis(el, options = {}) {
  const { maxLines = 1 } = options;
  const measurement = measureContainer(el);
  if (!measurement.overflows) return el;
  el.style = el.style || {};
  el.style.overflow = 'hidden';
  el.style.textOverflow = 'ellipsis';
  el.style.webkitLineClamp = maxLines;
  return el;
}

module.exports = { measureContainer, applyEllipsis };
