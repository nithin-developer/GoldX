import { useState } from 'react';
import { toast } from 'react-hot-toast';
import { useMutation } from '@tanstack/react-query';

import {
  Card,
  Stack,
  Alert,
  Button,
  Select,
  MenuItem,
  TextField,
  Typography,
  InputLabel,
  FormControl,
} from '@mui/material';

import { DashboardContent } from 'src/layouts/dashboard';
import { notificationService } from 'src/services/notification.service';

// ----------------------------------------------------------------------

export function NotificationsView() {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [target, setTarget] = useState('all');

  const mutation = useMutation({
    mutationFn: notificationService.sendNotification,
    onSuccess: () => {
      toast.success('Notification sent');
      setTitle('');
      setMessage('');
      setTarget('all');
    },
    onError: () => toast.error('Failed to send notification'),
  });

  const onSubmit = () => {
    if (!title.trim() || !message.trim()) {
      toast.error('Title and message are required');
      return;
    }

    mutation.mutate({ title: title.trim(), message: message.trim(), target });
  };

  return (
    <DashboardContent>
      <Typography variant="h4" sx={{ mb: 3 }}>
        Notifications
      </Typography>

      <Card sx={{ p: 3 }}>
        <Stack spacing={2}>
          <TextField label="Title" value={title} onChange={(event) => setTitle(event.target.value)} />
          <TextField
            label="Message"
            multiline
            minRows={4}
            value={message}
            onChange={(event) => setMessage(event.target.value)}
          />
          <FormControl>
            <InputLabel id="target-select">Target</InputLabel>
            <Select
              labelId="target-select"
              label="Target"
              value={target}
              onChange={(event) => setTarget(String(event.target.value))}
            >
              <MenuItem value="all">All Users</MenuItem>
              <MenuItem value="vip">VIP Users</MenuItem>
              <MenuItem value="standard">Standard Users</MenuItem>
            </Select>
          </FormControl>
          <Stack direction="row" justifyContent="flex-end">
            <Button variant="contained" onClick={onSubmit} disabled={mutation.isPending}>
              {mutation.isPending ? 'Sending...' : 'Send Notification'}
            </Button>
          </Stack>
          {mutation.isError && <Alert severity="error">Unable to send notification.</Alert>}
        </Stack>
      </Card>
    </DashboardContent>
  );
}
