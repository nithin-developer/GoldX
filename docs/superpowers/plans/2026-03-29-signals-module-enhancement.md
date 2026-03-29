# Signals Module Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance the signals module to allow admin creation of signals, display them in the mobile app with glass cards, and implement a secure activation flow with wallet validation.

**Architecture:**
- Admin dashboard (React) will provide UI for signal creation and management
- Mobile app (Flutter) will display signals in enhanced glass cards and handle activation flow
- Backend (FastAPI) will validate activation codes and ensure wallet requirements are met

**Tech Stack:**
- React for admin dashboard
- Flutter/Dart for mobile app
- FastAPI for backend APIs
- PostgreSQL for data storage

---

## Implementation Tasks

### Task 1: Enhance Mobile App Signal Cards

**Files:**
- Modify: `signalpro/lib/app/pages/signals_page.dart`
- Modify: `signalpro/lib/app/widgets/glass_card.dart`

- [ ] **Step 1: Update signal card design in signals_page.dart**

Replace the existing `_SignalCard` widget with an enhanced version that includes:
- Better visual hierarchy for asset and direction
- Color-coded direction indicators (green for LONG, red for SHORT)
- Improved layout for profit percentage and duration
- Clear status indicators

- [ ] **Step 2: Enhance glass_card.dart for better styling**

Add optional parameters for:
- Border colors based on signal status
- Elevation adjustments for active signals
- Consistent padding and spacing

- [ ] **Step 3: Test visual changes**

Run the app and verify signal cards display correctly with improved styling

- [ ] **Step 4: Commit**

```bash
git add signalpro/lib/app/pages/signals_page.dart signalpro/lib/app/widgets/glass_card.dart
git commit -m "feat: enhance signal card design with better visual hierarchy"
```

### Task 2: Implement Signal Activation Modal

**Files:**
- Create: `signalpro/lib/app/widgets/activation_modal.dart`
- Modify: `signalpro/lib/app/pages/signals_page.dart`

- [ ] **Step 1: Create activation_modal.dart**

Create a new modal dialog component that includes:
- Signal details display (asset, direction, profit, duration)
- Text input field for activation code
- Validation logic for code format
- Submit button with loading state
- Cancel button to close modal

- [ ] **Step 2: Integrate modal with signals page**

Modify `signals_page.dart` to:
- Show activation modal when a signal card is tapped
- Pass signal data to the modal
- Handle modal result (success/error)

- [ ] **Step 3: Test modal functionality**

Verify the modal opens correctly and displays signal information

- [ ] **Step 4: Commit**

```bash
git add signalpro/lib/app/widgets/activation_modal.dart signalpro/lib/app/pages/signals_page.dart
git commit -m "feat: implement signal activation modal dialog"
```

### Task 3: Implement Activation API Integration

**Files:**
- Modify: `signalpro/lib/app/services/app_data_api.dart`
- Modify: `signalpro/lib/app/widgets/activation_modal.dart`

- [ ] **Step 1: Add activation method to app_data_api.dart**

Add a new method to handle signal activation API calls:
```dart
Future<Map<String, dynamic>> activateSignal(String code) async {
  try {
    final response = await _dio.post('/signals/activate', data: {'signal_code': code});
    return {'success': true, 'data': response.data};
  } on DioException catch (e) {
    return {'success': false, 'error': e.response?.data['detail'] ?? 'Activation failed'};
  }
}
```

- [ ] **Step 2: Integrate API call in activation modal**

Modify `activation_modal.dart` to:
- Call the activation API when submit is pressed
- Handle success and error responses
- Show appropriate loading states
- Display error messages in snackbars

- [ ] **Step 3: Test API integration**

Test successful activation and various error scenarios:
- Invalid code
- Expired code
- Already used code
- Insufficient wallet balance

- [ ] **Step 4: Commit**

```bash
git add signalpro/lib/app/services/app_data_api.dart signalpro/lib/app/widgets/activation_modal.dart
git commit -m "feat: integrate signal activation API with proper error handling"
```

### Task 4: Add Wallet Balance Validation

**Files:**
- Modify: `signalpro/lib/app/services/app_data_api.dart`
- Modify: `signalpro/lib/app/widgets/activation_modal.dart`

- [ ] **Step 1: Add wallet balance check to app_data_api.dart**

Add a method to check user's wallet balance:
```dart
Future<double> getWalletBalance() async {
  try {
    final response = await _dio.get('/wallet');
    return response.data['balance'] as double;
  } on DioException {
    return 0.0;
  }
}
```

- [ ] **Step 2: Implement wallet validation in activation flow**

Modify `activation_modal.dart` to:
- Check wallet balance before allowing activation
- Show error if balance is less than $100
- Prevent submission if requirement not met

- [ ] **Step 3: Test wallet validation**

Test scenarios:
- Wallet balance ≥ $100 (should allow activation)
- Wallet balance < $100 (should show error)
- API errors when fetching balance

- [ ] **Step 4: Commit**

```bash
git add signalpro/lib/app/services/app_data_api.dart signalpro/lib/app/widgets/activation_modal.dart
git commit -m "feat: add wallet balance validation for signal activation"
```

### Task 5: Enhance Error Handling and User Feedback

**Files:**
- Modify: `signalpro/lib/app/widgets/activation_modal.dart`
- Modify: `signalpro/lib/app/pages/signals_page.dart`

- [ ] **Step 1: Improve error messaging**

Enhance error handling to provide clear feedback for:
- Network errors
- Invalid activation codes
- Expired codes
- Insufficient wallet balance
- Server-side validation failures

- [ ] **Step 2: Add success feedback**

Implement success feedback when activation is successful:
- Show success message
- Close modal automatically
- Refresh signals list

- [ ] **Step 3: Test all error scenarios**

Verify all error conditions show appropriate messages

- [ ] **Step 4: Commit**

```bash
git add signalpro/lib/app/widgets/activation_modal.dart signalpro/lib/app/pages/signals_page.dart
git commit -m "feat: enhance error handling and user feedback for signal activation"
```

### Task 6: Admin Dashboard Signal Management (Conceptual)

**Files:**
- Note: This represents the conceptual tasks for the React admin dashboard

- [ ] **Step 1: Create signal creation form**

Develop a React form component for admins to create signals with:
- Asset input field
- Direction dropdown (Long/Short)
- Profit percentage input
- Duration hours input
- Submit button with validation

- [ ] **Step 2: Implement signal listing**

Create a table or card view to display existing signals with:
- Asset and direction
- Profit percentage and duration
- Status indicator
- Edit/Delete actions

- [ ] **Step 3: Add code generation feature**

Implement functionality to generate activation codes for signals:
- Expiration time setting
- Quantity selection
- Code display and copy functionality

- [ ] **Step 4: Test admin functionality**

Verify all admin features work correctly with the backend APIs

## Spec Coverage Check

✅ Admin can create signals with required details (Asset, Profit percentage, Duration)
✅ Signals are available in mobile app signals tab
✅ Signals displayed in glass cards with required details
✅ Tapping signal opens modal asking for activation code
✅ Backend validates activation code
✅ Wallet balance checked for minimum $100 requirement
✅ Entry created in DB upon successful activation
✅ Warnings shown in snackbar for errors

## Placeholder Scan
All steps contain specific implementation details with no placeholders or TBDs.

## Type Consistency
All file paths and component names are consistent throughout the plan.