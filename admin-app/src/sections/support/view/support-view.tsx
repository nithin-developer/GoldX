import { useState } from 'react';
import { toast } from 'react-hot-toast';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import {
  Box,
  Card,
  Chip,
  List,
  Alert,
  Stack,
  Button,
  Divider,
  ListItem,
  TextField,
  Typography,
  ListItemText,
  CircularProgress,
} from '@mui/material';

import { DashboardContent } from 'src/layouts/dashboard';
import { supportService, type SupportChat } from 'src/services/support.service';

// ----------------------------------------------------------------------

export function SupportView() {
  const queryClient = useQueryClient();

  const [selectedChatId, setSelectedChatId] = useState<number | null>(null);
  const [message, setMessage] = useState('');

  const { data, isLoading, isError } = useQuery({
    queryKey: ['support-chats'],
    queryFn: supportService.getChats,
  });

  const chats: SupportChat[] = data ?? [];

  const selectedChat = chats.find((chat) => chat.id === selectedChatId) ?? chats[0] ?? null;

  const replyMutation = useMutation({
    mutationFn: supportService.replyToChat,
    onSuccess: () => {
      toast.success('Reply sent');
      setMessage('');
      queryClient.invalidateQueries({ queryKey: ['support-chats'] });
    },
    onError: () => toast.error('Failed to send reply'),
  });

  const onReply = () => {
    if (!selectedChat || !message.trim()) {
      return;
    }

    replyMutation.mutate({ chat_id: selectedChat.id, message: message.trim() });
  };

  return (
    <DashboardContent>
      <Typography variant="h4" sx={{ mb: 3 }}>
        Support
      </Typography>

      {isError && <Alert severity="error">Unable to load support chats.</Alert>}

      <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
        <Card sx={{ width: { xs: '100%', md: 340 }, p: 1 }}>
          <Typography variant="h6" sx={{ px: 2, py: 1 }}>
            Conversations
          </Typography>
          <Divider />

          {isLoading && (
            <Stack alignItems="center" sx={{ py: 4 }}>
              <CircularProgress size={24} />
            </Stack>
          )}

          {!isLoading && (
            <List>
              {chats.map((chat) => (
                <ListItem
                  key={chat.id}
                  divider
                  onClick={() => setSelectedChatId(chat.id)}
                  sx={{
                    cursor: 'pointer',
                    bgcolor: selectedChat?.id === chat.id ? 'action.selected' : undefined,
                  }}
                >
                  <ListItemText
                    primary={chat.user_email}
                    secondary={`Updated: ${new Date(chat.updated_at).toLocaleString()}`}
                  />
                </ListItem>
              ))}

              {chats.length === 0 && <ListItem>No chats yet.</ListItem>}
            </List>
          )}
        </Card>

        <Card sx={{ flex: 1, p: 2 }}>
          {!selectedChat && !isLoading && (
            <Typography color="text.secondary">Select a chat to view messages.</Typography>
          )}

          {selectedChat && (
            <Stack spacing={2}>
              <Stack direction="row" alignItems="center" justifyContent="space-between">
                <Typography variant="h6">{selectedChat.user_email}</Typography>
                <Chip size="small" label={`Chat #${selectedChat.id}`} />
              </Stack>

              <Divider />

              <Stack spacing={1.5} sx={{ maxHeight: 420, overflowY: 'auto', pr: 1 }}>
                {selectedChat.messages.map((item) => (
                  <Box
                    key={item.id}
                    sx={{
                      alignSelf: item.sender === 'admin' ? 'flex-end' : 'flex-start',
                      maxWidth: '82%',
                      p: 1.5,
                      borderRadius: 2,
                      bgcolor: item.sender === 'admin' ? 'primary.main' : 'grey.200',
                      color: item.sender === 'admin' ? 'primary.contrastText' : 'text.primary',
                    }}
                  >
                    <Typography variant="body2">{item.message}</Typography>
                    <Typography variant="caption" sx={{ opacity: 0.8 }}>
                      {new Date(item.created_at).toLocaleString()}
                    </Typography>
                  </Box>
                ))}
              </Stack>

              <Divider />

              <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5}>
                <TextField
                  fullWidth
                  placeholder="Reply to this conversation..."
                  value={message}
                  onChange={(event) => setMessage(event.target.value)}
                />
                <Button variant="contained" onClick={onReply} disabled={replyMutation.isPending}>
                  {replyMutation.isPending ? 'Sending...' : 'Reply'}
                </Button>
              </Stack>
            </Stack>
          )}
        </Card>
      </Stack>
    </DashboardContent>
  );
}
