import { CONFIG } from 'src/config-global';

import { ReferralsView } from 'src/sections/referrals/view';

// ----------------------------------------------------------------------

export default function Page() {
  return (
    <>
      <title>{`Referrals - ${CONFIG.appName}`}</title>
      <ReferralsView />
    </>
  );
}
