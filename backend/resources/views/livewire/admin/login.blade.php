<div class="login">
  <div class="l">
    <div class="brand" style="padding:0;font-size:22px">🧾 <span>Thandal</span></div>
    <div>
      <div style="font-size:34px;font-weight:600;line-height:1.2;max-width:14ch">Chit collection and repayments, in one place.</div>
      <div style="opacity:.75;margin-top:12px;max-width:40ch">Customers, agents and admins all log in with a mobile number and PIN.</div>
    </div>
    <div style="opacity:.6;font-size:13px">Super Admin console</div>
  </div>
  <div class="r">
    <form wire:submit="login" style="width:380px;max-width:100%">
      <h1 style="margin:0 0 4px;font-size:26px">Log in</h1>
      <div class="muted" style="margin-bottom:22px">Enter your mobile number and PIN.</div>
      @if($error)<div class="banner bad">⚠️ <div>{{ $error }}</div></div>@endif
      <div class="fld">
        <label for="mobile">Mobile number</label>
        <div class="mob"><span>+91</span><input id="mobile" wire:model="mobile" maxlength="10" inputmode="numeric" autocomplete="off"></div>
        @error('mobile')<div class="errt">{{ $message }}</div>@enderror
      </div>
      <div class="fld">
        <label for="pin">PIN</label>
        <input class="inp" id="pin" type="password" wire:model="pin" maxlength="4" inputmode="numeric" placeholder="••••">
        @error('pin')<div class="errt">{{ $message }}</div>@enderror
      </div>
      <button class="btn" style="width:100%" type="submit">Log in</button>
      <div style="border-top:1px solid var(--line);margin-top:22px;padding-top:18px;text-align:center">
        <div class="muted" style="margin-bottom:8px">New admin?</div>
        <a class="btn sec" style="width:100%;display:block;text-decoration:none;box-sizing:border-box" href="{{ route('admin.register') }}">Register as admin</a>
      </div>
    </form>
  </div>
</div>
