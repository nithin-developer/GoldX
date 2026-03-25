import { CONFIG } from 'src/config-global';

import { SignalsView } from 'src/sections/signals/view';

// ----------------------------------------------------------------------

export default function Page() {
  return (
    <>
      <title>{`Signals - ${CONFIG.appName}`}</title>
      <SignalsView />
    </>
  );
}
