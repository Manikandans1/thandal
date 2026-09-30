<div>
  <div class="ph"><div><div class="crumb"><a href="{{ route('customers.index') }}">Customers</a> › {{ $customer->customer_code }}</div>
    <h1>{{ $customer->user->name }}</h1><div class="muted">{{ $customer->customer_code }} · {{ ucfirst($customer->user->status) }}</div></div></div>
  <div class="grid g4" style="margin-bottom:16px">
    <div class="kpi"><div class="l">Active chits</div><div class="n">{{ $customer->chits->where('status','active')->count() }}</div></div>
    <div class="kpi"><div class="l">Outstanding</div><div class="n">{{ rupees($customer->outstandingPaise()) }}</div></div>
    <div class="kpi bad"><div class="l">Overdue</div><div class="n">{{ rupees($customer->overduePaise()) }}</div></div>
    <div class="kpi"><div class="l">ID proof</div><div class="n" style="font-size:16px">{{ $customer->currentIdentityDocument?->typeLabel() }} · •••• {{ $customer->currentIdentityDocument?->number_last4 }}</div></div>
  </div>
  <div class="grid g21">
    <div>
      <div class="card"><h3>Customer information</h3>
        <div class="kv"><span>Mobile</span><span>+91 {{ $customer->user->mobile }}</span></div>
        <div class="kv"><span>Address</span><span>{{ $customer->address }}</span></div>
        <div class="kv"><span>Customer since</span><span>{{ $customer->joined_on->format('d M Y') }}</span></div>
      </div>
      <div class="card"><h3>Chits</h3>
        <table class="t"><tr><th>Chit</th><th>Loan</th><th>Repayment</th><th class="r">Outstanding</th><th>Status</th></tr>
        @foreach($customer->chits as $c)
        <tr class="cl" onclick="location.href='{{ route('chits.show',$c) }}'"><td><b>{{ $c->chit_code }}</b></td><td>{{ rupees($c->loan_amount_paise) }}</td>
          <td>{{ rupees($c->installment_amount_paise) }} / {{ $c->unitLabel(false) }}</td><td class="r">{{ rupees($c->outstandingPaise()) }}</td>
          <td><span class="pill p-{{ $c->status==='active'?'ok':($c->status==='pending'?'warn':'mute') }}">{{ ucfirst($c->status) }}</span></td></tr>
        @endforeach
        </table>
      </div>
    </div>
    <div>
      <div class="card"><h3>Assigned agent</h3>
        @if($customer->agent)
        <div class="row" style="justify-content:flex-start;gap:12px"><span class="av">{{ strtoupper(substr($customer->agent->user->name,0,2)) }}</span>
          <div><b>{{ $customer->agent->user->name }}</b><div class="muted sm">{{ $customer->agent->agent_code }}</div></div></div>
        @else<div class="muted">Not assigned.</div>@endif
      </div>
      <div class="card"><h3>Assignment history</h3>
        <div class="tl">@foreach($customer->assignments as $a)
          <div class="ti"><b>{{ $a->agent->user->name }}</b><div class="muted sm">{{ $a->assigned_on->format('d M Y') }} · {{ $a->reason }}</div></div>
        @endforeach</div>
      </div>
    </div>
  </div>
</div>
