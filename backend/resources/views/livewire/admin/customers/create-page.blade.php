<div>
  <div class="ph"><div><div class="crumb"><a href="{{ route('customers.index') }}">Customers</a> › New</div><h1>Create customer</h1></div></div>
  @if($createdId)
    <div class="card center" style="max-width:420px">
      <div class="badge" style="background:var(--ok-bg);color:var(--ok)">✓</div>
      <b style="font-size:20px">Customer created</b><div class="muted">{{ $name }} · {{ $createdId }}</div>
      <div class="pinshow">{{ $createdPin }}</div>
      <div class="banner info">ℹ️ <div>Shown only once. Only a secure hash is stored.</div></div>
      <a class="btn" href="{{ route('customers.index') }}">Done</a>
    </div>
  @else
  <div class="grid g21">
    <div class="card">
      <h3>Customer information</h3>
      <div class="fld"><label>Full name *</label><input class="inp" wire:model="name">@error('name')<div class="errt">{{ $message }}</div>@enderror</div>
      <div class="frow">
        <div class="fld"><label>Mobile number (used to log in) *</label><div class="mob"><span>+91</span><input wire:model="mobile" maxlength="10"></div>@error('mobile')<div class="errt">{{ $message }}</div>@enderror</div>
        <div class="fld"><label>Assigned agent</label><select class="inp" wire:model="agent_id"><option value="">Not assigned</option>@foreach($agents as $a)<option value="{{ $a->id }}">{{ $a->user->name }} ({{ $a->agent_code }})</option>@endforeach</select></div>
      </div>
      <div class="fld"><label>Address *</label><textarea class="ta" wire:model="address"></textarea>@error('address')<div class="errt">{{ $message }}</div>@enderror</div>
      <h3>ID proof · submit any one</h3>
      <div class="frow">
        <div class="fld"><label>ID proof type *</label><select class="inp" wire:model="doc_type"><option value="">Select one…</option>
          @foreach(config('thandal.document_types') as $k=>$l)<option value="{{ $k }}">{{ $l }}</option>@endforeach</select>@error('doc_type')<div class="errt">{{ $message }}</div>@enderror</div>
        <div class="fld"><label>ID number *</label><input class="inp" wire:model="id_number">@error('id_number')<div class="errt">{{ $message }}</div>@enderror</div>
      </div>
      <div class="fld"><label>ID document photo *</label><input type="file" wire:model="document" accept="image/*">@error('document')<div class="errt">{{ $message }}</div>@enderror</div>
    </div>
    <div class="card"><h3>What happens next</h3>
      <div class="list muted">
        <div class="li">A Customer ID is generated.</div>
        <div class="li">A 4-digit PIN is generated and shown once.</div>
        <div class="li">The customer logs in with their mobile number and PIN.</div>
      </div>
    </div>
  </div>
  <div class="acts"><button class="btn" wire:click="save">Create customer</button><a class="btn gh" href="{{ route('customers.index') }}">Cancel</a></div>
  @endif
</div>
