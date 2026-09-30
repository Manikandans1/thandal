<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Reconcile Razorpay payments stuck "pending" for too long (functional spec §6.4 step 8).
Schedule::command('thandal:reconcile-payments')->everyFiveMinutes();
