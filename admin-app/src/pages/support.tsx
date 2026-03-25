import { CONFIG } from 'src/config-global';

import { SupportView } from 'src/sections/support/view';

// ----------------------------------------------------------------------

export default function Page() {
  return (
    <>
      <title>{`Support - ${CONFIG.appName}`}</title>
      <SupportView />
    </>
  );
}
