import { CONFIG } from 'src/config-global';

import { AnnouncementsView } from 'src/sections/announcements/view';

// ----------------------------------------------------------------------

export default function Page() {
  return (
    <>
      <title>{`Announcements - ${CONFIG.appName}`}</title>
      <AnnouncementsView />
    </>
  );
}
