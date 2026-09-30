<div>
  <div class="ph"><div><h1>Reports</h1><div class="muted">Choose a report. All reports can be exported as CSV or Excel.</div></div></div>
  <div class="grid g3">
    @foreach($reports as $key => $label)
    <a class="rc" style="text-decoration:none" href="{{ route('reports.index') }}?export={{ $key }}"><b>{{ $label }}</b><span>Export as CSV or Excel</span></a>
    @endforeach
  </div>
</div>
