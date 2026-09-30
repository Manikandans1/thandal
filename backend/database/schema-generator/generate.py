import os, re, shutil
from schema_dsl import TABLES, ENUMS
OUT='/mnt/user-data/outputs/thandal/backend'
def wipe(p):
    if os.path.exists(p): shutil.rmtree(p)
    os.makedirs(p)
for d in ['database/migrations']: wipe(f'{OUT}/{d}')
os.makedirs(f'{OUT}/database',exist_ok=True)
byname={t['name']:t for t in TABLES}
# ---- topological order
def deps(t): return {c[1][3:] for c in t['cols'] if c[1].startswith('fk:')} - {t['name']}
order=[];seen=set()
def visit(n):
    if n in seen: return
    for d in sorted(deps(byname[n])): visit(d)
    seen.add(n);order.append(n)
for t in TABLES: visit(t['name'])
def esc(s): return s.replace("'","''")
def sqltype(ty):
    k,_,a=ty.partition(':')
    return {'str':f'VARCHAR({a})','char':f'CHAR({a})','text':'TEXT','json':'JSON','money':'BIGINT UNSIGNED','smoney':'BIGINT','uint':'INT UNSIGNED',
     'usmall':'SMALLINT UNSIGNED','utiny':'TINYINT UNSIGNED','bool':'TINYINT(1)','date':'DATE','datetime':'DATETIME','ts':'TIMESTAMP NULL',
     'enum':'ENUM('+','.join("'"+x+"'" for x in a.split('|'))+')','fk':'BIGINT UNSIGNED'}[k]
def dflt_sql(v): return str(v) if isinstance(v,(int,float)) else "'"+esc(str(v))+"'"
def cols_of(t):
    for c in t['cols']:
        name,ty,o=c
        yield name,ty,o
# ---- DDL
ddl=['-- Thandal MySQL 8 schema (generated from schema_dsl.py, do not edit by hand)','-- Money is stored in paise (1 rupee = 100 paise). All FKs are RESTRICT: financial data is never deleted.',
     'SET NAMES utf8mb4;','SET FOREIGN_KEY_CHECKS=0;','']
def table_ddl(t):
    n=t['name'];lines=[]
    pk=t.get('pk')
    if not pk: lines.append('  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT')
    for name,ty,o in cols_of(t):
        s=f'  `{name}` {sqltype(ty)}'
        s+=' NULL' if o.get('null') else ' NOT NULL'
        if 'default' in o: s+=' DEFAULT '+dflt_sql(o['default'])
        elif o.get('null') and not ty.startswith('json'): s+=' DEFAULT NULL'
        if o.get('note'): s+=" COMMENT '"+esc(o['note'])+"'"
        lines.append(s)
    ts=t.get('timestamps',True)
    if ts is True: lines+=['  `created_at` TIMESTAMP NULL DEFAULT NULL','  `updated_at` TIMESTAMP NULL DEFAULT NULL']
    elif ts=='created': lines.append('  `created_at` TIMESTAMP NULL DEFAULT NULL')
    lines.append(f'  PRIMARY KEY (`{pk}`)' if pk else '  PRIMARY KEY (`id`)')
    for name,ty,o in cols_of(t):
        if o.get('unique') and not o.get('pk'): lines.append(f'  UNIQUE KEY `{n}_{name}_unique` (`{name}`)')
    for u in t.get('uniques',[]): lines.append(f'  UNIQUE KEY `{n}_'+'_'.join(u)+'_unique` ('+','.join(f'`{x}`' for x in u)+')')
    for name,ty,o in cols_of(t):
        if ty.startswith('fk:'):
            if not o.get('unique'): 
                covered=any(ix and ix[0]==name for ix in t.get('indexes',[]))
                if not covered: lines.append(f'  KEY `{n}_{name}_index` (`{name}`)')
            lines.append(f'  CONSTRAINT `{n}_{name}_foreign` FOREIGN KEY (`{name}`) REFERENCES `{ty[3:]}` (`id`) ON DELETE RESTRICT')
    for ix in t.get('indexes',[]): lines.append(f'  KEY `{n}_'+'_'.join(ix)+'_index` ('+','.join(f'`{x}`' for x in ix)+')')
    for cn,expr in t.get('checks',[]): lines.append(f'  CONSTRAINT `{cn}` CHECK ({expr})')
    return f'-- {t["note"]}\nCREATE TABLE `{n}` (\n'+',\n'.join(lines)+'\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;\n'
for n in order: ddl.append(table_ddl(byname[n]))
ddl.append("""-- Framework tables (Laravel Sanctum + database sessions for the admin web)
CREATE TABLE `personal_access_tokens` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tokenable_type` VARCHAR(255) NOT NULL,
  `tokenable_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `token` VARCHAR(64) NOT NULL,
  `abilities` TEXT NULL,
  `last_used_at` TIMESTAMP NULL DEFAULT NULL,
  `expires_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  KEY `personal_access_tokens_expires_at_index` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `sessions` (
  `id` VARCHAR(255) NOT NULL,
  `user_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `ip_address` VARCHAR(45) NULL DEFAULT NULL,
  `user_agent` TEXT NULL,
  `payload` LONGTEXT NOT NULL,
  `last_activity` INT NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS=1;
""")
open(f'{OUT}/database/schema.sql','w').write('\n'.join(ddl))
# ---- Laravel migrations
def phpval(v): return str(v) if isinstance(v,(int,float)) else "'"+str(v).replace("\\","\\\\").replace("'","\\'")+"'"
def lv_col(name,ty,o):
    k,_,a=ty.partition(':')
    if k=='fk':
        m=f"$table->foreignId('{name}')"
    else:
        m={'str':f"$table->string('{name}', {a})",'char':f"$table->char('{name}', {a})",'text':f"$table->text('{name}')",'json':f"$table->json('{name}')",
         'money':f"$table->unsignedBigInteger('{name}')",'smoney':f"$table->bigInteger('{name}')",'uint':f"$table->unsignedInteger('{name}')",
         'usmall':f"$table->unsignedSmallInteger('{name}')",'utiny':f"$table->unsignedTinyInteger('{name}')",'bool':f"$table->boolean('{name}')",
         'date':f"$table->date('{name}')",'datetime':f"$table->dateTime('{name}')",'ts':f"$table->timestamp('{name}')",
         'enum':f"$table->enum('{name}', ["+', '.join("'"+x+"'" for x in a.split('|'))+"])"}[k]
    if o.get('null'): m+='->nullable()'
    if 'default' in o: m+=f"->default({phpval(o['default'])})"
    if o.get('unique') and not o.get('pk'): m+='->unique()'
    if o.get('note'): m+=f"->comment({phpval(o['note'])})"
    if k=='fk': m+=f"->constrained('{a}')->restrictOnDelete()"
    return m+';'
for i,n in enumerate(order,1):
    t=byname[n];body=[]
    if not t.get('pk'): body.append('$table->id();')
    for name,ty,o in cols_of(t):
        line=lv_col(name,ty,o)
        if o.get('pk'): line=line.rstrip(';')+'->primary();'
        body.append(line)
    ts=t.get('timestamps',True)
    if ts is True: body.append('$table->timestamps();')
    elif ts=='created': body.append("$table->timestamp('created_at')->nullable();")
    for u in t.get('uniques',[]): body.append('$table->unique(['+', '.join("'"+x+"'" for x in u)+']);')
    for ix in t.get('indexes',[]): body.append('$table->index(['+', '.join("'"+x+"'" for x in ix)+']);')
    checks=''.join(f"\n        DB::statement('ALTER TABLE `{n}` ADD CONSTRAINT `{cn}` CHECK ({expr})');" for cn,expr in t.get('checks',[]))
    code=f"""<?php

use Illuminate\\Database\\Migrations\\Migration;
use Illuminate\\Database\\Schema\\Blueprint;
use Illuminate\\Support\\Facades\\DB;
use Illuminate\\Support\\Facades\\Schema;

/**
 * {t['note']}
 */
return new class extends Migration
{{
    public function up(): void
    {{
        Schema::create('{n}', function (Blueprint $table) {{
"""+''.join(f'            {b}\n' for b in body)+f"""        }});{checks}
    }}

    public function down(): void
    {{
        Schema::dropIfExists('{n}');
    }}
}};
"""
    open(f'{OUT}/database/migrations/2026_09_20_{i:06d}_create_{n}_table.php','w').write(code)
k=len(order)
open(f'{OUT}/database/migrations/2026_09_20_{k+1:06d}_create_personal_access_tokens_table.php','w').write("""<?php

use Illuminate\\Database\\Migrations\\Migration;
use Illuminate\\Database\\Schema\\Blueprint;
use Illuminate\\Support\\Facades\\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->morphs('tokenable');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable()->index();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('personal_access_tokens');
    }
};
""")
open(f'{OUT}/database/migrations/2026_09_20_{k+2:06d}_create_sessions_table.php','w').write("""<?php

use Illuminate\\Database\\Migrations\\Migration;
use Illuminate\\Database\\Schema\\Blueprint;
use Illuminate\\Support\\Facades\\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sessions');
    }
};
""")
# ---- mermaid ER + doc tables
def mtype(ty):
    k=ty.split(':')[0]; return {'fk':'bigint','str':'string','char':'string','money':'paise','smoney':'paise','usmall':'int','utiny':'int','uint':'int','bool':'bool'}.get(k,k)
er=['erDiagram']
for n in order:
    t=byname[n];er.append(f'  {n} {{'); er.append('    bigint id PK') if not t.get('pk') else None
    for name,ty,o in cols_of(t):
        tag=' FK' if ty.startswith('fk:') else (' UK' if o.get('unique') else '')
        er.append(f'    {mtype(ty)} {name}{tag}')
    er.append('  }')
for n in order:
    for name,ty,o in cols_of(byname[n]):
        if ty.startswith('fk:'):
            er.append(f'  {ty[3:]} ||--{"o|" if o.get("unique") else "o{"} {n} : "{name}"')
mer='\n'.join(er)
open('/mnt/user-data/outputs/thandal/docs/er-diagram.mmd','w').write(mer)
def human(ty):
    k,_,a=ty.partition(':')
    return {'str':f'string({a})','char':f'char({a})','money':'paise (unsigned)','smoney':'paise (signed)','usmall':'small int','utiny':'tiny int','uint':'int','bool':'yes/no','fk':f'→ {a}','enum':'one of: '+', '.join(a.split('|'))}.get(k,k)
docs=[]
for n in order:
    t=byname[n];docs.append(f"### `{n}`\n{t['note']}\n\n| Column | Type | Null | Notes |\n|---|---|---|---|")
    if not t.get('pk'): docs.append('| `id` | bigint | no | primary key |')
    for name,ty,o in cols_of(t):
        notes=[o['note']] if o.get('note') else []
        if o.get('unique'): notes.append('unique')
        if 'default' in o: notes.append(f"default {o['default']}")
        docs.append(f"| `{name}` | {human(ty)} | {'yes' if o.get('null') else 'no'} | {'; '.join(notes)} |")
    for cn,expr in t.get('checks',[]): docs.append(f'| _rule_ | `{expr}` | | enforced by the database (`{cn}`) |')
    docs.append('')
open('/mnt/user-data/outputs/thandal/backend/database/schema-generator/tables.md','w').write('\n'.join(docs))
print('order:',order)
