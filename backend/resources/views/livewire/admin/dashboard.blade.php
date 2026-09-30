<div>
  <div class="ph"><div><h1>Dashboard</h1></div></div>

  @if($pendingCorrections || $pendingChits || $pendingAdmins)
  <div class="banner warn">⚠️ <div><b>Needs attention:</b>
    @if($pendingCorrections) <a href="{{ route('payments.index') }}">{{ $pendingCorrections }} correction request(s)</a> waiting @endif
    @if($pendingChits) · {{ $pendingChits }} chit(s) waiting for disbursement @endif
    @if($pendingAdmins) · <a href="{{ route('admin-users') }}">{{ $pendingAdmins }} admin registration(s)</a> waiting @endif
  </div></div>
  @endif

  <div class="grid g4" style="margin-bottom:16px">
    <div class="kpi"><div class="l">Total customers</div><div class="n">{{ $customers }}</div></div>
    <div class="kpi"><div class="l">Active chits</div><div class="n">{{ $activeChits }}</div><div class="s">{{ $pendingChits }} pending disbursement</div></div>
    <div class="kpi hero"><div class="l">Today's expected</div><div class="n">{{ rupees($expectedToday) }}</div><div class="s">Due installments + overdue</div></div>
    <div class="kpi ok"><div class="l">Today's collected</div><div class="n">{{ rupees($collectedToday) }}</div><div class="s">{{ rupees($cashToday) }} cash · {{ rupees($onlineToday) }} online</div></div>
  </div>
  <div class="grid g4">
    <div class="kpi"><div class="l">Total outstanding</div><div class="n">{{ rupees($outstanding) }}</div></div>
    <div class="kpi bad"><div class="l">Total overdue</div><div class="n">{{ rupees($overdue) }}</div><div class="s">Missed installments, same amount</div></div>
  </div>
</div>
