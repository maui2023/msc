/**
 * MotoSewa Interactive Mockup Helper Script
 * Provides simulated state transitions, countdowns, and reactive UI triggers.
 */

// Global mock state
const MotoState = {
  activeTab: 'explore',
  holdRemainingSeconds: 600, // 10 minutes
  timerInterval: null,
  selectedBike: {
    name: 'Yamaha NVX 155 ABS',
    plate: 'V*** 8291',
    category: 'Skuter Automatik',
    engine: '155 cc',
    store: 'Cameron Moto Rental (Tanah Rata)',
    hours: 24,
    dayType: 'weekend',
    baseRate: 90.00,
    deposit: 50.00,
    fee: 2.00, // RM1 AffanPay + RM1 Platform
    total: 142.00
  },
  activeBooking: {
    ref: 'BK-20261017-8492',
    status: 'pending_payment',
    paymentStatus: 'pending',
    startTime: '2026-10-18 10:00 AM',
    endTime: '2026-10-19 10:00 AM',
    licenseStatus: 'pending'
  }
};

// Initialize PWA Renter Timer
function startHoldCountdown(displayElementId) {
  if (MotoState.timerInterval) clearInterval(MotoState.timerInterval);
  
  const el = document.getElementById(displayElementId);
  if (!el) return;

  function update() {
    const mins = Math.floor(MotoState.holdRemainingSeconds / 60);
    const secs = MotoState.holdRemainingSeconds % 60;
    el.innerText = `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;

    if (MotoState.holdRemainingSeconds <= 0) {
      clearInterval(MotoState.timerInterval);
      showToast('Tempoh 10 minit pegangan telah tamat. Inventori dilepaskan semula.', 'danger');
      el.innerText = '00:00 (TAMAT)';
    } else {
      MotoState.holdRemainingSeconds--;
    }
  }

  update();
  MotoState.timerInterval = setInterval(update, 1000);
}

// Switch PWA View/Tab
function switchPwaTab(tabName) {
  MotoState.activeTab = tabName;
  
  // Hide all screens
  document.querySelectorAll('.pwa-screen').forEach(el => el.classList.add('d-none'));
  
  // Show target screen
  const target = document.getElementById('screen-' + tabName);
  if (target) target.classList.remove('d-none');

  // Update bottom nav active state
  document.querySelectorAll('.pwa-nav-item').forEach(el => el.classList.remove('active'));
  const activeNav = document.getElementById('nav-' + tabName);
  if (activeNav) activeNav.classList.add('active');

  // Start timer if checkout screen
  if (tabName === 'checkout') {
    startHoldCountdown('hold-timer-text');
  }

  // Scroll to top of content area
  const content = document.getElementById('pwa-content');
  if (content) content.scrollTop = 0;
}

// Calculate Refund dynamically based on hours before start
function calculateRefundPreview(hoursBefore) {
  const eligibleRental = MotoState.selectedBike.baseRate; // RM 90.00
  const deposit = MotoState.selectedBike.deposit; // RM 50.00
  const fee = MotoState.selectedBike.fee; // RM 2.00 (Non-refundable)

  let percentage = 0;
  let ruleText = '';

  if (hoursBefore >= 24) {
    percentage = 75;
    ruleText = '≥ 24 Jam sebelum waktu mula sewaan (Polisi Pemilik: 75% refund sewaan)';
  } else if (hoursBefore >= 12) {
    percentage = 50;
    ruleText = '12 hingga 24 Jam sebelum waktu mula (Polisi Pemilik: 50% refund sewaan)';
  } else {
    percentage = 0;
    ruleText = '< 12 Jam sebelum waktu mula (Tiada refund sewaan)';
  }

  const refundRental = (eligibleRental * (percentage / 100));
  const totalRefund = refundRental + deposit; // Deposit always returned 100% on cancellation

  // Update UI elements if present
  const pctEl = document.getElementById('calc-refund-percent');
  const rentEl = document.getElementById('calc-refund-rent');
  const depEl = document.getElementById('calc-refund-deposit');
  const feeEl = document.getElementById('calc-refund-fee');
  const totalEl = document.getElementById('calc-refund-total');
  const ruleEl = document.getElementById('calc-refund-rule');

  if (pctEl) pctEl.innerText = percentage + '%';
  if (rentEl) rentEl.innerText = 'RM ' + refundRental.toFixed(2);
  if (depEl) depEl.innerText = 'RM ' + deposit.toFixed(2);
  if (feeEl) feeEl.innerText = 'RM ' + fee.toFixed(2) + ' (Hangus)';
  if (totalEl) totalEl.innerText = 'RM ' + totalRefund.toFixed(2);
  if (ruleEl) ruleEl.innerText = ruleText;
}

// Toast notification helper
function showToast(message, type = 'info') {
  let toastContainer = document.getElementById('toast-container');
  if (!toastContainer) {
    toastContainer = document.createElement('div');
    toastContainer.id = 'toast-container';
    toastContainer.className = 'toast-container position-fixed bottom-0 end-0 p-3';
    toastContainer.style.zIndex = 2000;
    document.body.appendChild(toastContainer);
  }

  const toastId = 'toast-' + Date.now();
  const bgClass = type === 'success' ? 'bg-success text-white' :
                  type === 'danger' ? 'bg-danger text-white' :
                  type === 'warning' ? 'bg-warning text-dark' : 'bg-primary text-white';

  const toastHtml = `
    <div id="${toastId}" class="toast align-items-center ${bgClass} border-0 show" role="alert" aria-live="assertive" aria-atomic="true">
      <div class="d-flex">
        <div class="toast-body fs-7">
          <i class="bi bi-info-circle-fill me-2"></i> ${message}
        </div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
      </div>
    </div>
  `;

  toastContainer.insertAdjacentHTML('beforeend', toastHtml);
  setTimeout(() => {
    const el = document.getElementById(toastId);
    if (el) el.remove();
  }, 4000);
}

// Add Manual / Walk-in Booking (Owner)
function handleOwnerManualBookingSubmit(e) {
  if (e) e.preventDefault();
  const name = document.getElementById('manual-cust-name')?.value || 'Encik Ahmad';
  const bike = document.getElementById('manual-bike-select')?.value || 'Yamaha Y15ZR (VAA 2319)';
  const method = document.getElementById('manual-method-select')?.value || 'cash';
  const amount = document.getElementById('manual-amount')?.value || '70.00';

  const badgeMethod = method === 'cash' 
    ? '<span class="badge bg-secondary">Tunai (Cash)</span>' 
    : '<span class="badge bg-info text-dark">QR Manual</span>';

  const tableBody = document.getElementById('owner-bookings-tbody');
  if (tableBody) {
    const newRow = `
      <tr class="table-warning">
        <td><strong>BK-MANUAL-${Math.floor(1000 + Math.random() * 9000)}</strong></td>
        <td>
          <span class="badge badge-owner-manual mb-1"><i class="bi bi-person-badge"></i> Walk-In Pemilik</span><br>
          ${name}
        </td>
        <td>${bike}</td>
        <td>Hari Ini ➔ Esok (24j)</td>
        <td>RM ${amount} <br>${badgeMethod}</td>
        <td><span class="badge bg-success">Confirmed</span></td>
        <td>
          <button class="btn btn-sm btn-outline-primary" onclick="showToast('Sedia untuk serahan kunci!')"><i class="bi bi-key"></i> Serah</button>
        </td>
      </tr>
    `;
    tableBody.insertAdjacentHTML('afterbegin', newRow);
  }

  // Close modal if open
  const modalEl = document.getElementById('modalWalkInBooking');
  if (modalEl) {
    const modal = bootstrap.Modal.getInstance(modalEl);
    if (modal) modal.hide();
  }

  showToast(`Tempahan walk-in untuk ${name} berjaya direkod! Ketersediaan inventori dikemas kini serta-merta.`, 'success');
}
