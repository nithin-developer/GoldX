import { CONFIG } from 'src/config-global';

import { ReportsView } from 'src/sections/reports/view';

// ----------------------------------------------------------------------

export default function Page() {
  return (
    <>
      <title>{`Reports - ${CONFIG.appName}`}</title>
      <ReportsView />
    </>
  );
}
