import { CONFIG } from 'src/config-global';

import { VipView } from 'src/sections/vip/view';

// ----------------------------------------------------------------------

export default function Page() {
  return (
    <>
      <title>{`VIP Users - ${CONFIG.appName}`}</title>
      <VipView />
    </>
  );
}
