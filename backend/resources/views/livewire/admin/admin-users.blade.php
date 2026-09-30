<div>
  <div class="ph"><div><h1>Admin users</h1><div class="muted">People who can log in to this console and the admin app.</div></div></div>
  <div class="tabs"><button class="{{ $tab==='admins'?'on':'' }}" wire:click="$set('tab','admins')">Admins</button>
    <button class="{{ $tab==='requests'?'on':'' }}" wire:click="$set('tab','requests')">Registration requests</button></div>
  @if($tab==='admins')
  <div class="card" style="padding:0"><table class="t"><tr><th>Admin</th><th>Mobile</th><th>Role</th><th>Status</th><th></th></tr>
    @foreach($admins as $a)
    <tr><td><b>{{ $a->name }}</b></td><td>+91 {{ $a->mobile }}</td><td>{{ $a->role==='super_admin'?'Super Admin':'Admin' }}</td>
      <td><span class="pill p-{{ $a->status==='active'?'ok':'mute' }}">{{ ucfirst($a->status) }}</span></td>
      <td>@if($a->role!=='super_admin')<button class="btn sec sm" wire:click="toggle({{ $a->id }})">{{ $a->status==='active'?'Deactivate':'Activate' }}</button>@else<span class="muted sm">Owner</span>@endif</td></tr>
    @endforeach
  </table></div>
  @else
  <div class="chips" style="margin-bottom:14px">@foreach(['pending'=>'Pending','active'=>'Approved','rejected'=>'Rejected'] as $k=>$l)
    <button class="chip {{ $reqStatus===$k?'on':'' }}" wire:click="$set('reqStatus','{{ $k }}')">{{ $l }}</button>@endforeach</div>
  <div class="card" style="padding:0"><table class="t"><tr><th>Name</th><th>Mobile</th><th>Requested</th>@if($reqStatus==='pending')<th></th>@endif</tr>
    @foreach($requests as $r)
    <tr><td>{{ $r->name }}</td><td>+91 {{ $r->mobile }}</td><td>{{ $r->created_at->format('d M Y, h:i A') }}</td>
      @if($reqStatus==='pending')<td><button class="btn sec sm" wire:click="approve({{ $r->id }})">Approve as admin</button> <button class="btn dg sm" wire:click="reject({{ $r->id }})">Reject</button></td>@endif
    </tr>
    @endforeach
  </table></div>
  @endif
</div>
