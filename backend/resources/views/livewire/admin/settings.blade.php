<div>
  <div class="ph"><div><h1>System settings</h1></div></div>
  @if(session('saved'))<div class="banner ok">✓ <div>Settings saved.</div></div>@endif
  <div class="card" style="max-width:640px">
    <div class="fld"><label>Support phone</label><input class="inp" wire:model="support_phone"></div>
    <div class="fld"><label>Office hours</label><input class="inp" wire:model="support_hours"></div>
    <div class="fld"><label>Receipt number prefix</label><input class="inp" wire:model="receipt_prefix"></div>
    <button class="btn" wire:click="save">Save</button>
  </div>
</div>
