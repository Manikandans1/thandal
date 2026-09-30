<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Super Admin web panel (Livewire, session-based auth, same login rules as the API)
|--------------------------------------------------------------------------
*/

Route::get('/', fn () => redirect('/login'));

Route::middleware('guest:web')->group(function () {
    Route::get('/login', \App\Livewire\Admin\Login::class)->name('login');
    Route::get('/register', \App\Livewire\Admin\RegisterAdmin::class)->name('admin.register');
});

Route::middleware(['auth:web', 'role.web:admin'])->group(function () {
    Route::get('/dashboard', \App\Livewire\Admin\Dashboard::class)->name('dashboard');
    Route::get('/customers', \App\Livewire\Admin\Customers\IndexPage::class)->name('customers.index');
    Route::get('/customers/create', \App\Livewire\Admin\Customers\CreatePage::class)->name('customers.create');
    Route::get('/customers/{customer}', \App\Livewire\Admin\Customers\ShowPage::class)->name('customers.show');
    Route::get('/agents', \App\Livewire\Admin\Agents\IndexPage::class)->name('agents.index');
    Route::get('/agents/create', \App\Livewire\Admin\Agents\CreatePage::class)->name('agents.create');
    Route::get('/chits', \App\Livewire\Admin\Chits\IndexPage::class)->name('chits.index');
    Route::get('/chits/create', \App\Livewire\Admin\Chits\CreatePage::class)->name('chits.create');
    Route::get('/chits/{chit}', \App\Livewire\Admin\Chits\ShowPage::class)->name('chits.show');
    Route::get('/payments', \App\Livewire\Admin\Payments\IndexPage::class)->name('payments.index');
    Route::get('/reports', \App\Livewire\Admin\Reports\IndexPage::class)->name('reports.index');
    Route::get('/audit-logs', \App\Livewire\Admin\AuditLogs::class)->name('audit-logs');
    Route::get('/settings', \App\Livewire\Admin\Settings::class)->name('settings');
    Route::middleware('role.web:super_admin')->group(function () {
        Route::get('/admin-users', \App\Livewire\Admin\AdminUsers::class)->name('admin-users');
    });
    Route::post('/logout', fn () => tap(auth('web')->logout(), fn () => request()->session()->invalidate()) && redirect('/login'))->name('logout');
});
