<div>
  <div class="ph"><div><h1>Chit accounts</h1><div class="muted">{{ $chits->total() }} chit accounts</div></div>
    <div class="acts"><a class="btn" href="{{ route('chits.create') }}">+ Create chit account</a></div></div>
  <div class="card" style="padding:0">
    <div class="tools"><div class="chips">
      @foreach(['All','Pending','Active','Completed','Cancelled'] as $s)
      <button class="chip {{ $status===$s?'on':'' }}" wire:click="$set('status','{{ $s }}')">{{ $s }}</button>
      @endforeach
    </div></div>
    <table class="t"><tr><th>Chit</th><th>Customer</th><th>Loan</th><th>Repayment</th><th class="r">Outstanding</th><th>Status</th></tr>
      @foreach($chits as $c)
      <tr class="cl" onclick="location.href='{{ route('chits.show',$c) }}'"><td><b>{{ $c->chit_code }}</b></td><td>{{ $c->customer->user->name }}</td>
        <td>{{ rupees($c->loan_amount_paise) }}</td><td>{{ rupees($c->installment_amount_paise) }}/{{ $c->unitLabel(false) }}</td>
        <td class="r">{{ rupees($c->outstandingPaise()) }}</td><td><span class="pill p-{{ $c->status==='active'?'ok':($c->status==='pending'?'warn':'mute') }}">{{ ucfirst($c->status) }}</span></td></tr>
      @endforeach
    </table>
    <div style="padding:14px 18px">{{ $chits->links() }}</div>
  </div>
</div>
