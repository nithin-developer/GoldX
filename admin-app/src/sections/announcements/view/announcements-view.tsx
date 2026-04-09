import type { AxiosError } from 'axios';

import { toast } from 'react-hot-toast';
import { useState, type ChangeEvent } from 'react';
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
  TablePagination,
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
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  const { data, isLoading, isError } = useQuery({
    queryKey: ['announcements', page, rowsPerPage],
    queryFn: () =>
      notificationService.getAnnouncements({
        skip: page * rowsPerPage,
        limit: rowsPerPage,
      }),
  });

  const announcements = data?.items ?? [];
  const totalAnnouncements = data?.total ?? 0;

  const handleChangePage = (_event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const mutation = useMutation({
    mutationFn: notificationService.createAnnouncement,
    onSuccess: () => {
      toast.success('Announcement created');
      setTitle('');
      setContent('');
      setDurationHours('24');
      queryClient.invalidateQueries({ queryKey: ['announcements'] });
    },
    onError: (error) => toast.error(resolveApiErrorMessage(error)),
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
              {announcements.map((item) => (
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

              {announcements.length === 0 && (
                <ListItem>
                  <ListItemText primary="No announcements yet." />
                </ListItem>
              )}
            </List>
          )}

          <TablePagination
            component="div"
            page={page}
            count={totalAnnouncements}
            rowsPerPage={rowsPerPage}
            onPageChange={handleChangePage}
            rowsPerPageOptions={[5, 10, 25]}
            onRowsPerPageChange={handleChangeRowsPerPage}
          />
        </Card>
      </Stack>
    </DashboardContent>
  );
}

function resolveApiErrorMessage(error: unknown): string {
  const axiosError = error as AxiosError<{ detail?: unknown; message?: string }>;
  const detail = axiosError.response?.data?.detail;

  if (typeof axiosError.response?.data?.message === 'string' && axiosError.response.data.message.trim()) {
    return axiosError.response.data.message;
  }

  if (typeof detail === 'string' && detail.trim()) {
    return detail;
  }

  if (Array.isArray(detail) && detail.length > 0) {
    const first = detail[0] as { msg?: string };
    if (first?.msg) {
      return first.msg;
    }
  }

  return 'Failed to create announcement';
}
