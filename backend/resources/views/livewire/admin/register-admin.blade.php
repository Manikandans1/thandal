<div class="login">
  <div class="l">
    <div class="brand" style="padding:0;font-size:22px">🧾 <span>Thandal</span></div>
    <div><div style="font-size:34px;font-weight:600;line-height:1.2;max-width:14ch">Join as an admin.</div>
    <div style="opacity:.75;margin-top:12px;max-width:40ch">Register with your mobile number. A Super Admin approves you before you can use the console.</div></div>
    <div style="opacity:.6;font-size:13px">Super Admin console</div>
  </div>
  <div class="r">
    @if($done)
      <div style="width:400px;max-width:100%">
        <div class="empty"><div class="badge" style="background:var(--ok-bg);color:var(--ok)">✓</div><b style="font-size:22px;display:block">Registration sent</b>Your request is waiting for a Super Admin.</div>
        <div class="banner info">ℹ️ <div>You will be able to log in with your mobile number and PIN after approval.</div></div>
        <a class="btn" style="width:100%;display:block;text-align:center;text-decoration:none;box-sizing:border-box" href="{{ route('login') }}">Back to log in</a>
      </div>
    @else
      <form wire:submit="register" style="width:400px;max-width:100%">
        <h1 style="margin:0 0 4px;font-size:26px">Register as admin</h1>
        <div class="muted" style="margin-bottom:18px">Create your admin login. You can log in after a Super Admin approves you.</div>
        <div class="banner info">ℹ️ <div>Until you are approved you can't see or change anything. Once approved you can perform all admin activities.</div></div>
        <div class="fld"><label>Full name</label><input class="inp" wire:model="name">@error('name')<div class="errt">{{ $message }}</div>@enderror</div>
        <div class="fld"><label>Mobile number</label><div class="mob"><span>+91</span><input wire:model="mobile" maxlength="10"></div>@error('mobile')<div class="errt">{{ $message }}</div>@enderror</div>
        <div class="frow">
          <div class="fld"><label>Create PIN</label><input class="inp" type="password" wire:model="pin" maxlength="4">@error('pin')<div class="errt">{{ $message }}</div>@enderror</div>
          <div class="fld"><label>Confirm PIN</label><input class="inp" type="password" wire:model="pin_confirmation" maxlength="4">@error('pin_confirmation')<div class="errt">{{ $message }}</div>@enderror</div>
        </div>
        <button class="btn" style="width:100%" type="submit">Submit registration</button>
        <a class="btn gh" style="width:100%;display:block;text-align:center;margin-top:10px;text-decoration:none;box-sizing:border-box" href="{{ route('login') }}">Back to log in</a>
      </form>
    @endif
  </div>
</div>
