// Highlight.js loader for Phoenix LiveView
import hljs from '../vendor/highlight/highlight.min.js';

// Highlight all code blocks
function highlightAllCodeBlocks() {
  if (hljs) {
    document.querySelectorAll('pre > code:not(.hljs)').forEach((block) => {
      hljs.highlightElement(block);
    });
  }
}

// Listen for LiveView page updates
window.addEventListener('phx:update', highlightAllCodeBlocks);

export { highlightAllCodeBlocks };
