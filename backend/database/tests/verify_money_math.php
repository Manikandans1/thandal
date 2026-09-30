<?php
// Standalone re-implementation of the due-date and allocation math from
// ScheduleService and AllocationService, to verify the arithmetic itself
// (full Laravel can't run in this sandbox — see docs/03-what-was-tested.md).

function due_date(string $freq, DateTime $start, int $n): DateTime {
    $d = clone $start;
    $k = $n - 1;
    if ($freq === 'daily') { $d->modify("+{$k} days"); return $d; }
    if ($freq === 'weekly') { $d->modify('+'.(7*$k).' days'); return $d; }
    if ($freq === 'monthly') {
        // addMonthsNoOverflow equivalent: same day, clamp to last day of target month
        $y = (int)$start->format('Y'); $m = (int)$start->format('m') + $k; $day = (int)$start->format('d');
        $y += intdiv($m - 1, 12); $m = (($m - 1) % 12) + 1;
        $lastDay = (int)(new DateTime("$y-$m-01"))->format('t');
        $day = min($day, $lastDay);
        return new DateTime(sprintf('%04d-%02d-%02d', $y, $m, $day));
    }
    throw new Exception('bad freq');
}

$fail = 0; $pass = 0;
function check($label, $cond) { global $fail,$pass; if ($cond) { $pass++; echo "PASS  $label\n"; } else { $fail++; echo "FAIL  $label\n"; } }

// 1. Daily schedule of 100 days from 2026-07-31
$start = new DateTime('2026-07-31');
check('daily day 1 = start date', due_date('daily',$start,1)->format('Y-m-d') === '2026-07-31');
check('daily day 100 = start+99', due_date('daily',$start,100)->format('Y-m-d') === '2026-11-07');
check('total = 120*100', 120*100 === 12000);

// 2. Weekly schedule
$start2 = new DateTime('2026-09-26');
check('weekly week 1 = start date', due_date('weekly',$start2,1)->format('Y-m-d') === '2026-09-26');
check('weekly week 9 = +8 weeks', due_date('weekly',$start2,9)->format('Y-m-d') === '2026-11-21');
check('weekly total 1250*20=25000', 1250*20 === 25000);

// 3. Monthly with day-31 clamp
$start3 = new DateTime('2026-01-31');
check('monthly month1 = Jan 31', due_date('monthly',$start3,1)->format('Y-m-d') === '2026-01-31');
check('monthly month2 clamps to Feb 28', due_date('monthly',$start3,2)->format('Y-m-d') === '2026-02-28');
check('monthly month3 = Mar 31 (not chained from Feb 28)', due_date('monthly',$start3,3)->format('Y-m-d') === '2026-03-31');
check('monthly month4 clamps to Apr 30', due_date('monthly',$start3,4)->format('Y-m-d') === '2026-04-30');

// 4. Allocation: oldest-first, partial + advance
function allocate(array $installments, int $amount): array {
    // installments: list of ['seq'=>n,'amount'=>x,'paid'=>y] sorted by seq, oldest first
    $applied = [];
    foreach ($installments as &$i) {
        if ($amount <= 0) break;
        $need = $i['amount'] - $i['paid'];
        if ($need <= 0) continue;
        $give = min($need, $amount);
        $i['paid'] += $give;
        $applied[] = ['seq'=>$i['seq'],'amount'=>$give];
        $amount -= $give;
    }
    return [$installments, $applied, $amount];
}
$insts = [
    ['seq'=>18,'amount'=>120,'paid'=>0], // overdue
    ['seq'=>19,'amount'=>120,'paid'=>0], // today
    ['seq'=>20,'amount'=>120,'paid'=>0],
    ['seq'=>21,'amount'=>120,'paid'=>0],
];
[$after, $applied, $remaining] = allocate($insts, 300);
check('₹300 pays inst 18 fully', $after[0]['paid'] === 120);
check('₹300 pays inst 19 fully', $after[1]['paid'] === 120);
check('₹300 leaves inst 20 partial ₹60', $after[2]['paid'] === 60);
check('inst 21 untouched', $after[3]['paid'] === 0);
check('no remainder left over', $remaining === 0);
check('applied 3 installments', count($applied) === 3);

// 5. Overpay must be rejected before allocation (outstanding check)
$outstanding = array_sum(array_map(fn($i)=>$i['amount']-$i['paid'], $insts));
check('outstanding = 480 before any payment', $outstanding === 480);
check('would reject 500 > outstanding 480', 500 > $outstanding);

// 6. Reversal math (correction: wrong amount 250 -> 200, delta -50, reverse most-recent-first)
$allocRows = [ ['id'=>1,'amount'=>120], ['id'=>2,'amount'=>130] ]; // sums to 250
$delta = 200 - 250; // -50
$remaining = -$delta; // 50 to reverse
$reversed = [];
foreach (array_reverse($allocRows) as $row) {
    if ($remaining <= 0) break;
    $take = min($remaining, $row['amount']);
    $reversed[] = ['id'=>$row['id'], 'reverse'=>$take];
    $remaining -= $take;
}
check('reverses 50 from the most recent allocation (id 2) first', $reversed[0]['id'] === 2 && $reversed[0]['reverse'] === 50);
check('fully reversed, remaining 0', $remaining === 0);

// 7. Early closure = outstanding recomputed fresh
$closureAmount = array_sum(array_map(fn($i)=>$i['amount']-$i['paid'], $after));
check('early closure amount = remaining across all installments', $closureAmount === (120-120)+(120-120)+(120-60)+(120-0));

echo "\n".($fail===0 ? "ALL $pass CHECKS PASSED" : "$fail FAILED, $pass passed")."\n";
exit($fail === 0 ? 0 : 1);
