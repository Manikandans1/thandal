<div>
  <div class="ph"><div><h1>Audit logs</h1></div></div>
  <input class="inp s" wire:model.live.debounce.400ms="q" placeholder="Search entity or text" style="margin-bottom:14px">
  <div class="tl">
    @foreach($logs as $log)
    <div class="ti"><b>{{ $log->action }}</b> <span class="muted">· {{ $log->entity_id }}</span>
      <div class="sm">{{ $log->summary }}</div><div class="muted sm">{{ $log->created_at->format('d M Y, h:i A') }} · {{ $log->actor_label }}</div></div>
    @endforeach
  </div>
  {{ $logs->links() }}
</div>
