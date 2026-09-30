<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{ $title ?? 'Thandal' }} · Thandal Admin</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="{{ asset('css/tokens.css') }}">
<link rel="stylesheet" href="{{ asset('css/admin.css') }}">
@livewireStyles
</head>
<body>
<div class="adm">
  <aside class="sbar">
    <div class="brand">🧾 <span>Thandal<small>Super Admin</small></span></div>
    <button class="nl {{ request()->routeIs('dashboard') ? 'on' : '' }}" onclick="location.href='{{ route('dashboard') }}'">📊 <span class="lbl">Dashboard</span></button>
    <div class="nsec">Manage</div>
    <button class="nl {{ request()->routeIs('customers.*') ? 'on' : '' }}" onclick="location.href='{{ route('customers.index') }}'">👥 <span class="lbl">Customers</span></button>
    <button class="nl {{ request()->routeIs('agents.*') ? 'on' : '' }}" onclick="location.href='{{ route('agents.index') }}'">🧑‍💼 <span class="lbl">Agents</span></button>
    <button class="nl {{ request()->routeIs('chits.*') ? 'on' : '' }}" onclick="location.href='{{ route('chits.index') }}'">📒 <span class="lbl">Chit accounts</span></button>
    <div class="nsec">Money</div>
    <button class="nl {{ request()->routeIs('payments.*') ? 'on' : '' }}" onclick="location.href='{{ route('payments.index') }}'">💳 <span class="lbl">Payments</span></button>
    <button class="nl {{ request()->routeIs('reports.*') ? 'on' : '' }}" onclick="location.href='{{ route('reports.index') }}'">📈 <span class="lbl">Reports</span></button>
    <div class="nsec">System</div>
    <button class="nl {{ request()->routeIs('audit-logs') ? 'on' : '' }}" onclick="location.href='{{ route('audit-logs') }}'">🧾 <span class="lbl">Audit logs</span></button>
    @if(auth()->user()?->isSuperAdmin())
    <button class="nl {{ request()->routeIs('admin-users') ? 'on' : '' }}" onclick="location.href='{{ route('admin-users') }}'">🔒 <span class="lbl">Admin users</span></button>
    @endif
    <button class="nl {{ request()->routeIs('settings') ? 'on' : '' }}" onclick="location.href='{{ route('settings') }}'">⚙️ <span class="lbl">System settings</span></button>
    <div style="flex:1"></div>
    <form method="POST" action="{{ route('logout') }}">@csrf<button class="nl" type="submit">🚪 <span class="lbl">Log out</span></button></form>
  </aside>
  <div class="main">
    <header class="tb">
      <label class="gs">🔍 <input placeholder="Search customers, chits, receipts…"></label>
      <span class="sp"></span>
      <button class="me"><span class="av">{{ strtoupper(substr(auth()->user()->name,0,2)) }}</span>
        <span style="text-align:left"><b style="display:block;font-size:13.5px">{{ auth()->user()->name }}</b><span class="muted sm">{{ auth()->user()->role === 'super_admin' ? 'Super Admin' : 'Admin' }}</span></span></button>
    </header>
    <main class="content">{{ $slot }}</main>
  </div>
</div>
@livewireScripts
</body>
</html>
