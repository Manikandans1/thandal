<?php

use Carbon\Carbon;

if (! function_exists('rupees')) {
    /** Format paise as an Indian-grouped rupee string, e.g. 21117000 -> "₹2,11,170". */
    function rupees(int $paise): string
    {
        $r = intdiv($paise, 100);
        $sign = $r < 0 ? '-' : '';
        $r = abs($r);
        $s = (string) $r;
        if (strlen($s) > 3) {
            $last3 = substr($s, -3);
            $rest = substr($s, 0, -3);
            $rest = preg_replace('/\B(?=(\d{2})+(?!\d))/', ',', $rest);
            $s = $rest.','.$last3;
        }

        return $sign.'₹'.$s;
    }
}

if (! function_exists('today_ist')) {
    function today_ist(): Carbon
    {
        return Carbon::now('Asia/Kolkata')->startOfDay();
    }
}
