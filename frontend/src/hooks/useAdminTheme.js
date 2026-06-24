import { useState, useEffect } from 'react';

export function useAdminTheme() {
  const [isDark, setIsDark] = useState(
    () => localStorage.getItem('admin-theme') === 'dark'
  );

  useEffect(() => {
    localStorage.setItem('admin-theme', isDark ? 'dark' : 'light');
  }, [isDark]);

  const toggle = () => setIsDark(d => !d);

  return [isDark, toggle];
}
