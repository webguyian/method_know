export const tagFilter = {
  mounted() {
    this.el.addEventListener('keydown', (event) => {
      if (event.key === 'Enter') {
        event.preventDefault();
        setTimeout(() => {
          // Clear input value after submitting tag
          this.el.value = '';
        }, 0);
      }
    });
    this.el.addEventListener('blur', (e) => {
      setTimeout(() => {
        this.pushEventTo(this.el, 'hide_tag_dropdown', {});
      }, 200); // 200ms delay allows click to process first
    });
  }
};
