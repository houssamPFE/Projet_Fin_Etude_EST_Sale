import { create } from 'zustand';

const useThemeStore = create((set) => ({
  theme: localStorage.getItem('theme-accent') || 'cream',
  setTheme: (theme) => {
    localStorage.setItem('theme-accent', theme);
    
    // Apply body classes
    if (theme === 'cream') {
      document.body.classList.add('theme-cream');
    } else {
      document.body.classList.remove('theme-cream');
    }
    
    set({ theme });
  },
  
  initTheme: () => {
    const theme = localStorage.getItem('theme-accent') || 'cream';
    if (theme === 'cream') {
      document.body.classList.add('theme-cream');
    } else {
      document.body.classList.remove('theme-cream');
    }
    set({ theme });
  }
}));

export default useThemeStore;
