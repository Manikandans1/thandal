# Schema generator

`schema.sql`, every file in `../migrations/`, `docs/er-diagram.mmd` and the table
reference in `docs/02-database-design.md` are all generated from **one** file:
`schema_dsl.py`. This guarantees the SQL, the Laravel migrations and the
documentation can never disagree with each other.

To add a column or a table: edit `schema_dsl.py`, then run:

```bash
python3 generate.py
```

(needs only Python 3, no other dependencies). It regenerates all four outputs in
place. Re-run `database/tests/verify_schema.sh` afterwards to check the rules still hold.
