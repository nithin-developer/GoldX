import { CONFIG } from 'src/config-global';

import { WithdrawalsView } from 'src/sections/withdrawals/view';

// ----------------------------------------------------------------------

export default function Page() {
  return (
    <>
      <title>{`Withdrawals - ${CONFIG.appName}`}</title>
      <WithdrawalsView />
    </>
  );
}
