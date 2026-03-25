import { useState } from 'react';
import { toast } from 'react-hot-toast';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import {
  Card,
  List,
  Chip,
  Stack,
  Alert,
  Button,
  Divider,
  ListItem,
  TextField,
  Typography,
  ListItemText,
  CircularProgress,
} from '@mui/material';

import { DashboardContent } from 'src/layouts/dashboard';
import { notificationService } from 'src/services/notification.service';

// ----------------------------------------------------------------------

export function AnnouncementsView() {
  const queryClient = useQueryClient();

  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [durationHours, setDurationHours] = useState('24');

  const { data, isLoading, isError } = useQuery({
    queryKey: ['announcements'],
    queryFn: notificationService.getAnnouncements,
  });

  const mutation = useMutation({
    mutationFn: notificationService.createAnnouncement,
    onSuccess: () => {
      toast.success('Announcement created');
      setTitle('');
      setContent('');
      setDurationHours('24');
      queryClient.invalidateQueries({ queryKey: ['announcements'] });
    },
    onError: () => toast.error('Failed to create announcement'),
  });

  const onSubmit = () => {
    if (!title.trim() || !content.trim()) {
      toast.error('Title and content are required');
      return;
    }

    const duration = Number(durationHours);
    if (Number.isNaN(duration) || duration <= 0) {
      toast.error('Duration must be a positive number');
      return;
    }

    mutation.mutate({
      title: title.trim(),
      content: content.trim(),
      duration_hours: duration,
    });
  };

  return (
    <DashboardContent>
      <Typography variant="h4" sx={{ mb: 3 }}>
        Announcements
      </Typography>

      <Stack spacing={3}>
        <Card sx={{ p: 3 }}>
          <Stack spacing={2}>
            <TextField label="Title" value={title} onChange={(event) => setTitle(event.target.value)} />
            <TextField
              label="Content"
              multiline
              minRows={4}
              value={content}
              onChange={(event) => setContent(event.target.value)}
            />
            <TextField
              label="Duration (hours)"
              type="number"
              value={durationHours}
              onChange={(event) => setDurationHours(event.target.value)}
            />
            <Stack direction="row" justifyContent="flex-end">
              <Button variant="contained" onClick={onSubmit} disabled={mutation.isPending}>
                {mutation.isPending ? 'Creating...' : 'Create Announcement'}
              </Button>
            </Stack>
          </Stack>
        </Card>

        <Card sx={{ p: 1 }}>
          <Typography variant="h6" sx={{ px: 2, py: 1 }}>
            Active Announcements
          </Typography>
          <Divider />

          {isLoading && (
            <Stack alignItems="center" sx={{ py: 4 }}>
              <CircularProgress size={24} />
            </Stack>
          )}

          {isError && <Alert severity="error">Unable to load announcements.</Alert>}

          {!isLoading && !isError && (
            <List>
              {(data ?? []).map((item) => (
                <ListItem key={item.id} divider>
                  <ListItemText
                    primary={item.title}
                    secondary={
                      <>
                        {item.content}
                        <br />
                        Expires: {new Date(item.expires_at).toLocaleString()}
                      </>
                    }
                  />
                  <Chip size="small" color="info" label={`${item.duration_hours}h`} />
                </ListItem>
              ))}

              {(data ?? []).length === 0 && (
                <ListItem>
                  <ListItemText primary="No announcements yet." />
                </ListItem>
              )}
            </List>
          )}
        </Card>
      </Stack>
    </DashboardContent>
  );
}
