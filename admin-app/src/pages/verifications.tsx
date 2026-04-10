import { CONFIG } from 'src/config-global';

import { VerificationsView } from 'src/sections/verifications/view';

// ----------------------------------------------------------------------

export default function Page() {
  return (
    <>
      <title>{`Verifications - ${CONFIG.appName}`}</title>
      <VerificationsView />
    </>
  );
}
