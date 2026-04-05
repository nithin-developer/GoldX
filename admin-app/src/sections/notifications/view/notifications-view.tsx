import { useState } from 'react';
import { toast } from 'react-hot-toast';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import {
  Card,
  Chip,
  Stack,
  Table,
  Alert,
  Button,
  Select,
  TableRow,
  MenuItem,
  TextField,
  TableBody,
  TableCell,
  TableHead,
  Typography,
  InputLabel,
  FormControl,
  TableContainer,
  CircularProgress,
} from '@mui/material';

import { DashboardContent } from 'src/layouts/dashboard';
import { getApiErrorMessage } from 'src/services/auth.service';
import { notificationService, type NotificationData } from 'src/services/notification.service';

import { ConfirmDialog } from 'src/components/confirm-dialog';

// ----------------------------------------------------------------------

export function NotificationsView() {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [target, setTarget] = useState('all');
  const [deleteNotificationId, setDeleteNotificationId] = useState<number | null>(null);

  const queryClient = useQueryClient();

  // For sending notifications
  const sendMutation = useMutation({
    mutationFn: notificationService.sendNotification,
    onSuccess: () => {
      toast.success('Notification sent');
      setTitle('');
      setMessage('');
      setTarget('all');
    },
    onError: () => toast.error('Failed to send notification'),
  });

  // For managing notifications
  const { data: notifications, isLoading, isError } = useQuery({
    queryKey: ['notifications'],
    queryFn: notificationService.getNotifications,
  });

  const deleteMutation = useMutation({
    mutationFn: notificationService.deleteNotification,
    onSuccess: () => {
      toast.success('Notification deleted');
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      setDeleteNotificationId(null);
    },
    onError: (error) => toast.error(getApiErrorMessage(error, 'Failed to delete notification')),
  });

  const onSubmit = () => {
    if (!title.trim() || !message.trim()) {
      toast.error('Title and message are required');
      return;
    }

    sendMutation.mutate({ title: title.trim(), message: message.trim(), target });
  };

  return (
    <DashboardContent>
      <Typography variant="h4" sx={{ mb: 3 }}>
        Notifications
      </Typography>

      <Card sx={{ p: 3, mb: 3 }}>
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
            <Button variant="contained" onClick={onSubmit} disabled={sendMutation.isPending}>
              {sendMutation.isPending ? 'Sending...' : 'Send Notification'}
            </Button>
          </Stack>
          {sendMutation.isError && <Alert severity="error">Unable to send notification.</Alert>}
        </Stack>
      </Card>

      <Card>
        <Typography variant="h6" sx={{ p: 3, pb: 2 }}>
          Notification Management
        </Typography>

        {isError && <Alert severity="error" sx={{ mx: 3, mb: 2 }}>Unable to load notifications.</Alert>}

        <TableContainer sx={{ p: 3, pt: 0 }}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Title</TableCell>
                <TableCell>Message</TableCell>
                <TableCell>Type</TableCell>
                <TableCell>Date</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading && (
                <TableRow>
                  <TableCell colSpan={5} align="center">
                    <CircularProgress size={24} />
                  </TableCell>
                </TableRow>
              )}

              {!isLoading && (!notifications || notifications.length === 0) && (
                <TableRow>
                  <TableCell colSpan={5} align="center">
                    No notifications found.
                  </TableCell>
                </TableRow>
              )}

              {notifications && notifications.map((notification) => (
                <TableRow key={notification.id} hover>
                  <TableCell>{notification.title}</TableCell>
                  <TableCell>{notification.message}</TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      label={notification.type}
                      color={notification.type === 'system' ? 'primary' : 'secondary'}
                    />
                  </TableCell>
                  <TableCell>
                    {new Date(notification.created_at).toLocaleDateString()}
                  </TableCell>
                  <TableCell align="right">
                    <Button
                      size="small"
                      variant="outlined"
                      color="error"
                      onClick={() => setDeleteNotificationId(notification.id)}
                    >
                      Delete
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Card>

      <ConfirmDialog
        open={deleteNotificationId !== null}
        onClose={() => setDeleteNotificationId(null)}
        onConfirm={() => {
          if (deleteNotificationId) {
            deleteMutation.mutate(deleteNotificationId);
          }
        }}
        title="Delete Notification"
        content="Are you sure you want to delete this notification? This action cannot be undone."
        confirmText="Delete Notification"
        confirmColor="error"
        isPending={deleteMutation.isPending}
      />
    </DashboardContent>
  );
}