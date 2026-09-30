<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/** Gap-free counters (customer/chit/agent/receipt/correction numbers). Always read with lockForUpdate(). */
class Sequence extends Model
{
    public $timestamps = false;
    public $incrementing = false;
    protected $primaryKey = 'name';
    protected $keyType = 'string';

    protected $fillable = ['name', 'value'];
}
