<div>
  <div class="ph"><div><h1>Payments</h1></div></div>
  <div class="tabs"><button class="{{ $tab==='list'?'on':'' }}" wire:click="$set('tab','list')">All payments</button>
    <button class="{{ $tab==='corr'?'on':'' }}" wire:click="$set('tab','corr')">Correction requests</button></div>
  @if($tab==='list')
  <div class="card" style="padding:0"><table class="t"><tr><th>Receipt</th><th>Customer</th><th>Chit</th><th>Method</th><th class="r">Amount</th><th>Status</th></tr>
    @foreach($payments as $p)
    <tr><td>{{ $p->receipt_number ?? '—' }}</td><td>{{ $p->customer->user->name }}</td><td>{{ $p->chit->chit_code }}</td>
      <td><span class="pill p-mute">{{ ucfirst($p->method) }}</span></td><td class="r">{{ rupees($p->effectiveAmountPaise()) }}</td>
      <td><span class="pill p-{{ $p->status==='confirmed'?'ok':($p->status==='pending'?'warn':'bad') }}">{{ ucfirst($p->status) }}</span></td></tr>
    @endforeach
  </table><div style="padding:14px 18px">{{ $payments->links() }}</div></div>
  @else
  <div class="chips" style="margin-bottom:14px">
    @foreach(['pending'=>'Pending','approved'=>'Approved','rejected'=>'Rejected'] as $k=>$l)
    <button class="chip {{ $correctionStatus===$k?'on':'' }}" wire:click="$set('correctionStatus','{{ $k }}')">{{ $l }}</button>
    @endforeach
  </div>
  <div class="card" style="padding:0"><table class="t"><tr><th>Request</th><th>Customer</th><th>Agent</th><th>Reason</th><th>Status</th>@if($correctionStatus==='pending')<th></th>@endif</tr>
    @foreach($corrections as $c)
    <tr><td><b>{{ $c->code }}</b></td><td>{{ $c->payment->customer->user->name }}</td><td>{{ $c->requestedByAgent->user->name }}</td>
      <td>{{ str_replace('_',' ',$c->reason) }}</td><td><span class="pill p-warn">{{ ucfirst($c->status) }}</span></td>
      @if($correctionStatus==='pending')<td><button class="btn sec sm" wire:click="approve({{ $c->id }})">Approve</button> <button class="btn dg sm" wire:click="reject({{ $c->id }})">Reject</button></td>@endif
    </tr>
    @endforeach
  </table></div>
  @endif
</div>
