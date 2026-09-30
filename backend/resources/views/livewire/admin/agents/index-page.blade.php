<div>
  <div class="ph"><div><h1>Agents</h1><div class="muted">{{ $agents->count() }} agents</div></div>
    <div class="acts"><a class="btn" href="{{ route('agents.create') }}">+ Create agent</a></div></div>
  <div class="card" style="padding:0"><table class="t"><tr><th>Agent</th><th>Mobile</th><th class="r">Customers</th><th>Status</th></tr>
    @foreach($agents as $a)
    <tr><td><b>{{ $a->user->name }}</b><div class="muted sm">{{ $a->agent_code }}</div></td><td>+91 {{ $a->user->mobile }}</td>
      <td class="r">{{ $a->customers_count }}</td><td><span class="pill p-{{ $a->user->status==='active'?'ok':'mute' }}">{{ ucfirst($a->user->status) }}</span></td></tr>
    @endforeach
  </table></div>
</div>
