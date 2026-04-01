import { toast } from 'react-hot-toast';
import { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import {
  Box,
  Card,
  Stack,
  Alert,
  Button,
  TextField,
  Typography,
  CircularProgress,
} from '@mui/material';

import { DashboardContent } from 'src/layouts/dashboard';
import {
  walletAdminService,
  type DepositSettings,
} from 'src/services/wallet-admin.service';

import { Iconify } from 'src/components/iconify';

// ----------------------------------------------------------------------

type SettingsForm = {
  currency: string;
  network: string;
  wallet_address: string;
  instructions: string;
};

const initialForm: SettingsForm = {
  currency: 'USDT',
  network: 'TRC20',
  wallet_address: '',
  instructions: '',
};

export function SettingsView() {
  const queryClient = useQueryClient();

  const [form, setForm] = useState<SettingsForm>(initialForm);
  const [selectedQrCode, setSelectedQrCode] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);

  const { data, isLoading, isError } = useQuery({
    queryKey: ['admin-deposit-settings'],
    queryFn: walletAdminService.getDepositSettings,
  });

  useEffect(() => {
    if (!data) {
      return;
    }

    setForm({
      currency: data.currency || 'USDT',
      network: data.network || '',
      wallet_address: data.wallet_address || '',
      instructions: data.instructions || '',
    });

    setPreviewUrl((previous) => {
      if (previous?.startsWith('blob:')) {
        URL.revokeObjectURL(previous);
      }

      return data.qr_code_url || null;
    });
  }, [data]);

  useEffect(
    () => () => {
      if (previewUrl?.startsWith('blob:')) {
        URL.revokeObjectURL(previewUrl);
      }
    },
    [previewUrl]
  );

  const saveMutation = useMutation({
    mutationFn: walletAdminService.updateDepositSettings,
    onSuccess: (updatedSettings: DepositSettings) => {
      toast.success('Deposit settings updated');
      setSelectedQrCode(null);
      setPreviewUrl((previous) => {
        if (previous?.startsWith('blob:')) {
          URL.revokeObjectURL(previous);
        }

        return updatedSettings.qr_code_url || null;
      });
      queryClient.invalidateQueries({ queryKey: ['admin-deposit-settings'] });
    },
    onError: () => toast.error('Failed to update settings'),
  });

  const onSelectFile = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) {
      return;
    }

    setSelectedQrCode(file);
    const localUrl = URL.createObjectURL(file);
    setPreviewUrl((previous) => {
      if (previous?.startsWith('blob:')) {
        URL.revokeObjectURL(previous);
      }

      return localUrl;
    });
  };

  const onSave = () => {
    if (!form.wallet_address.trim()) {
      toast.error('Wallet address is required');
      return;
    }

    saveMutation.mutate({
      currency: form.currency.trim() || 'USDT',
      network: form.network.trim(),
      wallet_address: form.wallet_address.trim(),
      instructions: form.instructions.trim(),
      qr_code: selectedQrCode || undefined,
    });
  };

  return (
    <DashboardContent>
      <Typography variant="h4" sx={{ mb: 3 }}>
        Settings
      </Typography>

      {isError && <Alert severity="error">Unable to load settings.</Alert>}

      {isLoading && (
        <Stack alignItems="center" sx={{ py: 4 }}>
          <CircularProgress size={24} />
        </Stack>
      )}

      {!isLoading && (
        <Card sx={{ p: 3 }}>
          <Stack spacing={2.5}>
            <Typography variant="h6">Deposit Wallet Settings</Typography>

            <TextField
              label="Currency"
              value={form.currency}
              onChange={(event) => setForm((previous) => ({ ...previous, currency: event.target.value }))}
              placeholder="USDT"
            />

            <TextField
              label="Network"
              value={form.network}
              onChange={(event) => setForm((previous) => ({ ...previous, network: event.target.value }))}
              placeholder="TRC20"
            />

            <TextField
              label="Wallet Address"
              value={form.wallet_address}
              onChange={(event) =>
                setForm((previous) => ({ ...previous, wallet_address: event.target.value }))
              }
              placeholder="Enter wallet address for deposits"
            />

            <TextField
              label="Instructions"
              multiline
              minRows={4}
              value={form.instructions}
              onChange={(event) =>
                setForm((previous) => ({ ...previous, instructions: event.target.value }))
              }
              placeholder="Optional notes shown to users in the app"
            />

            <Stack spacing={1}>
              <Typography variant="subtitle2">Deposit QR Code</Typography>
              <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} alignItems="center">
                <Button
                  component="label"
                  variant="outlined"
                  startIcon={<Iconify icon="mingcute:add-line" />}
                >
                  {selectedQrCode ? 'Change QR Code' : 'Upload QR Code'}
                  <input
                    hidden
                    type="file"
                    accept="image/png,image/jpeg,image/webp"
                    onChange={onSelectFile}
                  />
                </Button>

                <Typography variant="body2" color="text.secondary">
                  {selectedQrCode ? selectedQrCode.name : 'PNG, JPG, JPEG, WEBP'}
                </Typography>
              </Stack>
            </Stack>

            {previewUrl && (
              <Box
                component="img"
                src={previewUrl}
                alt="Deposit QR code"
                sx={{
                  width: 200,
                  height: 200,
                  objectFit: 'cover',
                  borderRadius: 1,
                  border: (theme) => `1px solid ${theme.palette.divider}`,
                }}
              />
            )}

            <Stack direction="row" justifyContent="flex-end">
              <Button variant="contained" onClick={onSave} disabled={saveMutation.isPending}>
                {saveMutation.isPending ? 'Saving...' : 'Save Settings'}
              </Button>
            </Stack>
          </Stack>
        </Card>
      )}
    </DashboardContent>
  );
}
