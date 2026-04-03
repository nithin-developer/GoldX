import { useState } from 'react';
import { toast } from 'react-hot-toast';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import {
  Card,
  Chip,
  Alert,
  Stack,
  Table,
  Button,
  Dialog,
  Select,
  Switch,
  MenuItem,
  TableRow,
  TableBody,
  TableCell,
  TableHead,
  TextField,
  IconButton,
  InputLabel,
  Typography,
  DialogTitle,
  FormControl,
  DialogActions,
  DialogContent,
  TableContainer,
  CircularProgress,
  FormControlLabel,
} from '@mui/material';

import { DashboardContent } from 'src/layouts/dashboard';
import {
  signalService,
  type SignalData,
  type SignalCodeResponse,
  type CreateSignalPayload,
} from 'src/services/signal.service';

import { Iconify } from 'src/components/iconify';

// ----------------------------------------------------------------------

type SignalFormState = {
  asset: string;
  direction: string;
  profit_percent: string;
  duration_hours: string;
  vip_only: boolean;
};

const initialForm: SignalFormState = {
  asset: 'BTC/USDT',
  direction: 'buy',
  profit_percent: '75',
  duration_hours: '24',
  vip_only: false,
};

export function SignalsView() {
  const queryClient = useQueryClient();

  const [createOpen, setCreateOpen] = useState(false);
  const [codeOpen, setCodeOpen] = useState(false);
  const [codeResult, setCodeResult] = useState<SignalCodeResponse | null>(null);
  const [form, setForm] = useState<SignalFormState>(initialForm);

  const { data, isLoading, isError } = useQuery({
    queryKey: ['signals'],
    queryFn: signalService.getSignals,
  });

  const createMutation = useMutation({
    mutationFn: (payload: CreateSignalPayload) => signalService.createSignal(payload),
    onSuccess: () => {
      toast.success('Signal created');
      setCreateOpen(false);
      setForm(initialForm);
      queryClient.invalidateQueries({ queryKey: ['signals'] });
    },
    onError: () => toast.error('Failed to create signal'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => signalService.deleteSignal(id),
    onSuccess: () => {
      toast.success('Signal deleted');
      queryClient.invalidateQueries({ queryKey: ['signals'] });
    },
    onError: () => toast.error('Failed to delete signal'),
  });

  const codeMutation = useMutation({
    mutationFn: (signalId: string) => signalService.generateCode(signalId),
    onSuccess: (result) => {
      setCodeResult(result);
      setCodeOpen(true);
    },
    onError: () => toast.error('Failed to generate code'),
  });

  const onCreateSignal = () => {
    const payload: CreateSignalPayload = {
      asset: form.asset.trim(),
      direction: form.direction,
      profit_percent: Number(form.profit_percent),
      duration_hours: Number(form.duration_hours),
      vip_only: form.vip_only,
    };

    if (
      !payload.asset ||
      Number.isNaN(payload.profit_percent) ||
      Number.isNaN(payload.duration_hours)
    ) {
      toast.error('Please fill all signal fields correctly');
      return;
    }

    createMutation.mutate(payload);
  };

  const signals: SignalData[] = data ?? [];
  const formatCreatedAt = (value?: string) => {
    if (!value) {
      return '--';
    }

    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) {
      return '--';
    }

    return parsed.toLocaleString();
  };

  const isSignalExpired = (signal: SignalData) => {
    if (!signal.created_at) {
      return false;
    }
    const createdAt = new Date(signal.created_at);
    if (Number.isNaN(createdAt.getTime())) {
      return false;
    }
    const now = new Date();
    const expiresAt = new Date(createdAt.getTime() + signal.duration_hours * 60 * 60 * 1000);
    console.log({ signal, createdAt, expiresAt, now, expired: now > expiresAt });
    return now > expiresAt;
  };

  const expiresAtLabel = (() => {
    if (!codeResult?.expires_at) {
      return '--';
    }

    const parsed = new Date(codeResult.expires_at);
    if (Number.isNaN(parsed.getTime())) {
      return '--';
    }

    return parsed.toLocaleString();
  })();

  return (
    <DashboardContent>
      <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 3 }}>
        <Typography variant="h4">Signals</Typography>
        <Button
          variant="contained"
          startIcon={<Iconify icon="mingcute:add-line" />}
          onClick={() => setCreateOpen(true)}
        >
          Create Signal
        </Button>
      </Stack>

      {isError && <Alert severity="error">Unable to load signals right now.</Alert>}

      <Card>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Asset</TableCell>
                <TableCell>Direction</TableCell>
                <TableCell>Profit %</TableCell>
                <TableCell>Duration (h)</TableCell>
                <TableCell>Access</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Created At</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading && (
                <TableRow>
                  <TableCell colSpan={8} align="center">
                    <CircularProgress size={24} />
                  </TableCell>
                </TableRow>
              )}

              {!isLoading && signals.length === 0 && (
                <TableRow>
                  <TableCell colSpan={8} align="center">
                    No signals found.
                  </TableCell>
                </TableRow>
              )}

              {signals.map((signal) => (
                <TableRow key={signal.id} hover>
                  <TableCell>{signal.asset}</TableCell>
                  <TableCell>{signal.direction.toUpperCase()}</TableCell>
                  <TableCell>{signal.profit_percent}%</TableCell>
                  <TableCell>{signal.duration_hours}</TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      color={signal.vip_only ? 'warning' : 'default'}
                      label={signal.vip_only ? 'VIP Only' : 'All Users'}
                    />
                  </TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      color={isSignalExpired(signal) ? 'error' : 'success'}
                      label={isSignalExpired(signal) ? 'Expired' : 'Active'}
                    />
                  </TableCell>
                  <TableCell>{formatCreatedAt(signal.created_at)}</TableCell>
                  <TableCell align="right">
                    <Stack direction="row" spacing={1} justifyContent="flex-end">
                      <Button
                        size="small"
                        variant="outlined"
                        onClick={() => codeMutation.mutate(signal.id)}
                        disabled={codeMutation.isPending}
                      >
                        Show Code
                      </Button>
                      <IconButton
                        color="error"
                        onClick={() => deleteMutation.mutate(signal.id)}
                        disabled={deleteMutation.isPending}
                      >
                        <Iconify icon="solar:trash-bin-trash-bold" />
                      </IconButton>
                    </Stack>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Card>

      <Dialog open={createOpen} onClose={() => setCreateOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>Create Signal</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            {/* <TextField
              label="Asset"
              value={form.asset}
              onChange={(event) => setForm((prev) => ({ ...prev, asset: event.target.value }))}
              placeholder="BTC/USDT"
            /> */}
            <FormControl fullWidth>
              <InputLabel id="asset-label">Asset</InputLabel>
              <Select
                labelId="asset-label"
                label="Asset"
                value={form.asset}
                onChange={(event) =>
                  setForm((prev) => ({ ...prev, asset: String(event.target.value) }))
                }
              >
                <MenuItem value="BTC/USDT">BTC/USDT</MenuItem>
                <MenuItem value="ETH/USDT">ETH/USDT</MenuItem>
                <MenuItem value="BNB/USDT">BNB/USDT</MenuItem>
                <MenuItem value="SOL/USDT">SOL/USDT</MenuItem>
                <MenuItem value="XRP/USDT">XRP/USDT</MenuItem>
              </Select>
            </FormControl>

            <FormControl fullWidth>
              <InputLabel id="direction-label">Direction</InputLabel>
              <Select
                labelId="direction-label"
                label="Direction"
                value={form.direction}
                onChange={(event) =>
                  setForm((prev) => ({ ...prev, direction: String(event.target.value) }))
                }
              >
                <MenuItem value="buy">Buy</MenuItem>
                <MenuItem value="sell">Sell</MenuItem>
              </Select>
            </FormControl>
            <TextField
              type="number"
              label="Profit Percent"
              value={form.profit_percent}
              onChange={(event) =>
                setForm((prev) => ({ ...prev, profit_percent: event.target.value }))
              }
            />
            <TextField
              type="number"
              label="Duration Hours"
              value={form.duration_hours}
              onChange={(event) =>
                setForm((prev) => ({ ...prev, duration_hours: event.target.value }))
              }
            />
            <FormControlLabel
              control={
                <Switch
                  checked={form.vip_only}
                  onChange={(event) =>
                    setForm((prev) => ({ ...prev, vip_only: event.target.checked }))
                  }
                />
              }
              label="VIP only signal"
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={onCreateSignal} disabled={createMutation.isPending}>
            {createMutation.isPending ? 'Creating...' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

      <Dialog open={codeOpen} onClose={() => setCodeOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>Generated Signal Code</DialogTitle>
        <DialogContent>
          {codeResult && (
            <Stack spacing={2} sx={{ mt: 1 }}>
              <TextField
                value={codeResult.code}
                multiline
                minRows={3}
                inputProps={{ readOnly: true }}
              />
              <Typography variant="body2" color="text.secondary">
                Expires at: {expiresAtLabel}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Usage: {codeResult.used ? 'Already used' : 'Not used yet'}
              </Typography>
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCodeOpen(false)}>Close</Button>
          <Button
            variant="contained"
            onClick={() => {
              if (!codeResult) return;
              navigator.clipboard.writeText(codeResult.code);
              toast.success('Code copied');
            }}
          >
            Copy
          </Button>
        </DialogActions>
      </Dialog>
    </DashboardContent>
  );
}
