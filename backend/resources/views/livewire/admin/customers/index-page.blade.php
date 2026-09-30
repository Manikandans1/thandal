<div>
  <div class="ph"><div><h1>Customers</h1><div class="muted">{{ $customers->total() }} customers</div></div>
    <div class="acts"><a class="btn" href="{{ route('customers.create') }}">+ Create customer</a></div></div>
  <div class="card" style="padding:0">
    <div class="tools">
      <input class="inp s" wire:model.live.debounce.400ms="q" placeholder="Search name, ID or mobile">
      <select class="sel" wire:model.live="status"><option>All</option><option>Active</option><option>Inactive</option></select>
    </div>
    <div class="tw"><table class="t"><tr><th>Customer</th><th>Mobile</th><th>Agent</th><th class="r">Outstanding</th><th>Status</th></tr>
      @forelse($customers as $c)
      <tr class="cl" onclick="location.href='{{ route('customers.show', $c) }}'">
        <td><b>{{ $c->user->name }}</b><div class="muted sm">{{ $c->customer_code }}</div></td>
        <td>+91 {{ $c->user->mobile }}</td>
        <td>{{ $c->agent?->user?->name ?? 'Not assigned' }}</td>
        <td class="r num">{{ rupees($c->outstandingPaise()) }}</td>
        <td><span class="pill p-{{ $c->user->status==='active'?'ok':'mute' }}">{{ ucfirst($c->user->status) }}</span></td>
      </tr>
      @empty
      <tr><td colspan="5" class="empty">No customers match.</td></tr>
      @endforelse
    </table></div>
    <div style="padding:14px 18px">{{ $customers->links() }}</div>
  </div>
</div>
