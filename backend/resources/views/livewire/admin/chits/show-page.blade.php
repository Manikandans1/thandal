<div>
  <div class="ph"><div><div class="crumb"><a href="{{ route('chits.index') }}">Chit accounts</a> › {{ $chit->chit_code }}</div>
    <h1>{{ $chit->chit_code }}</h1><div class="muted">{{ $chit->customer->user->name }} · {{ ucfirst($chit->status) }}</div></div></div>
  <div class="grid g4" style="margin-bottom:16px">
    <div class="kpi hero"><div class="l">Total repayment</div><div class="n">{{ rupees($chit->total_repayment_paise) }}</div></div>
    <div class="kpi ok"><div class="l">Paid</div><div class="n">{{ rupees($chit->paid_paise) }}</div><div class="s">{{ $chit->paid_installments }} of {{ $chit->installment_count }}</div></div>
    <div class="kpi"><div class="l">Outstanding</div><div class="n">{{ rupees($chit->outstandingPaise()) }}</div></div>
    <div class="kpi"><div class="l">Loan amount</div><div class="n">{{ rupees($chit->loan_amount_paise) }}</div></div>
  </div>
  <div class="grid g2">
    <div class="card"><h3>Terms</h3>
      <div class="kv"><span>Repayment</span><span>{{ rupees($chit->installment_amount_paise) }} every {{ $chit->unitLabel(false) }}</span></div>
      <div class="kv"><span>Number of installments</span><span>{{ $chit->installment_count }} {{ $chit->unitLabel() }}</span></div>
      <div class="kv"><span>Start date</span><span>{{ $chit->start_date->format('d M Y') }}</span></div>
      <div class="kv"><span>End date</span><span>{{ $chit->end_date->format('d M Y') }}</span></div>
    </div>
    <div class="card"><h3>Schedule (first 10)</h3>
      <table class="t"><tr><th>#</th><th>Date</th><th class="r">Due</th><th class="r">Paid</th><th>Status</th></tr>
      @foreach($chit->installments->take(10) as $i)
      <tr><td>{{ $i->sequence }}</td><td>{{ $i->due_date->format('d M') }}</td><td class="r">{{ rupees($i->amount_paise) }}</td><td class="r">{{ rupees($i->paid_paise) }}</td>
        <td><span class="pill p-{{ ['paid'=>'ok','overdue'=>'bad','due_today'=>'warn'][$i->displayStatus()] ?? 'mute' }}">{{ str_replace('_',' ',$i->displayStatus()) }}</span></td></tr>
      @endforeach
      </table>
    </div>
  </div>
  @if($chit->status === 'pending')
  <div class="card" style="margin-top:16px"><h3>Record disbursement</h3>
    <div class="banner warn">⚠️ <div>The loan amount has not been given yet. The chit stays Pending until this is completed.</div></div>
    <div class="fld"><label>Method</label>
      <div style="display:flex;gap:8px">
        <button type="button" class="radio {{ $disb_method==='cash'?'on':'' }}" style="margin:0" wire:click="$set('disb_method','cash')"><span class="rd"></span>Cash</button>
        <button type="button" class="radio {{ $disb_method==='bank_transfer'?'on':'' }}" style="margin:0" wire:click="$set('disb_method','bank_transfer')"><span class="rd"></span>Bank transfer</button>
      </div>
    </div>
    @if($disb_method==='bank_transfer')<div class="fld"><label>Reference number *</label><input class="inp" wire:model="disb_reference">@error('disb_reference')<div class="errt">{{ $message }}</div>@enderror</div>@endif
    <button class="btn" wire:click="disburse">Save disbursement</button>
  </div>
  @endif
</div>
