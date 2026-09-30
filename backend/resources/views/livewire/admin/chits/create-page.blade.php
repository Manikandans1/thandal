<div>
  <div class="ph"><div><div class="crumb"><a href="{{ route('chits.index') }}">Chit accounts</a> › New</div><h1>Create chit account</h1></div></div>
  <div class="grid g21">
    <div class="card">
      <h3>Loan and repayment</h3>
      <div class="fld"><label>Customer *</label>
        <select class="inp" wire:model="customer_id"><option value="">Select a customer…</option>
          @foreach($customers as $c)<option value="{{ $c->id }}">{{ $c->user->name }} ({{ $c->customer_code }})</option>@endforeach
        </select>
        @error('customer_id')<div class="errt">{{ $message }}</div>@enderror
      </div>
      <div class="fld"><label>Loan amount (₹) *</label><input class="inp" wire:model="loan_amount" inputmode="numeric" placeholder="10000">@error('loan_amount')<div class="errt">{{ $message }}</div>@enderror</div>
      <div class="fld"><label>Repayment frequency *</label>
        <div style="display:flex;gap:8px">
          @foreach(['daily'=>'Daily','weekly'=>'Weekly','monthly'=>'Monthly'] as $val => $label)
          <button type="button" class="radio {{ $frequency===$val?'on':'' }}" style="margin:0" wire:click="$set('frequency','{{ $val }}')"><span class="rd"></span><span>{{ $label }}</span></button>
          @endforeach
        </div>
      </div>
      <div class="frow">
        <div class="fld"><label>Number of installments ({{ $this->unit }}s) *</label><input class="inp" wire:model.live="installment_count" inputmode="numeric">@error('installment_count')<div class="errt">{{ $message }}</div>@enderror</div>
        <div class="fld"><label>Installment amount (₹ every {{ $this->unit }}) *</label><input class="inp" wire:model.live="installment_amount" inputmode="numeric">@error('installment_amount')<div class="errt">{{ $message }}</div>@enderror
          <div class="help">You set this amount. There is no interest rate.</div></div>
      </div>
      <div class="frow"><div class="fld"><label>Start date *</label><input class="inp" type="date" wire:model="start_date">@error('start_date')<div class="errt">{{ $message }}</div>@enderror</div></div>
      <div class="fld"><label>Notes</label><textarea class="ta" wire:model="notes" placeholder="Optional"></textarea></div>
    </div>
    <div>
      <div class="card" style="background:var(--tint)">
        <h3>Preview (from the server)</h3>
        <div class="kv"><span>Loan amount</span><span>{{ $loan_amount ? rupees($loan_amount*100) : '—' }}</span></div>
        <div class="kv"><span>Repayment</span><span>{{ $installment_amount ? rupees($installment_amount*100).' every '.$this->unit : '—' }}</span></div>
        <div class="kv"><span>Installments</span><span>{{ $installment_count ? $installment_count.' '.$this->unit.'s' : '—' }}</span></div>
        <div class="row" style="margin-top:14px;padding-top:14px;border-top:1px solid var(--line);align-items:flex-end">
          <div><b style="font-size:15px">Total to pay</b><div class="muted sm">{{ $installment_amount && $installment_count ? rupees($installment_amount*100).' × '.$installment_count.' '.$this->unit.'s' : 'Enter the amounts on the left' }}</div></div>
          <b class="num" style="font-size:28px;color:var(--primary)">{{ $this->totalToPay ? rupees($this->totalToPay*100) : '—' }}</b>
        </div>
      </div>
      <div class="banner info">ℹ️ <div>The chit is created as <b>Pending</b>. It becomes <b>Active</b> once you record the disbursement.</div></div>
    </div>
  </div>
  <div class="acts"><button class="btn" wire:click="save">Create chit account</button><a class="btn gh" href="{{ route('chits.index') }}">Cancel</a></div>
</div>
