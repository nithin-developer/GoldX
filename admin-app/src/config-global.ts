import packageJson from '../package.json';

// ----------------------------------------------------------------------

export type ConfigValue = {
  appName: string;
  appVersion: string;
  apiUrl: string;
};

export const CONFIG: ConfigValue = {
  appName: 'Trading Signals Admin',
  appVersion: packageJson.version,
  apiUrl: import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1',
};
