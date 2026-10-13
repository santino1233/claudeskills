# wizpay: local payment methods in the deploy wizard (2026-10-02)
Branch feature/wizard-local-payments (from feature/growth-g2-conversion), worktree /tank/nxeon-wt-wizpay (real node_modules copy).
Design + owner actions: docs/DOCUMENTATION.md "Local payment methods in the deploy wizard".
Throwaway Postgres for the DB test: /tank/pg-wizpay (port 55439, db wizpay), started by me; stop with
  su postgres -c "/usr/lib/postgresql/17/bin/pg_ctl -D /tank/pg-wizpay/data stop"
Not verified: any real Stripe call, any browser render, Stripe-side acceptance of each method/currency/amount limits.
