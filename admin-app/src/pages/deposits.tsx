import { CONFIG } from 'src/config-global';

import { DepositsView } from 'src/sections/deposits/view';

// ----------------------------------------------------------------------

export default function Page() {
  return (
    <>
      <title>{`Deposits - ${CONFIG.appName}`}</title>
      <DepositsView />
    </>
  );
}
