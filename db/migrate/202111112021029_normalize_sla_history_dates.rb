# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

# Normalize issue bounds once instead of reading timezone settings per journal.
# Results are unchanged, so existing incremental caches remain valid.
class NormalizeSlaHistoryDates < ActiveRecord::Migration[5.2]
  def up
    execute "DROP FUNCTION IF EXISTS sla_get_spent ;" if RedmineSla::DbDialect.adapter == :mysql
    execute RedmineSla::DbDialect.function_sql('sla_get_spent')
  end

  def down
    # This migration only redeploys a function that remains compatible with
    # earlier plugin schemas. Keeping the optimized implementation avoids
    # silently replacing it with an older, unmaintained function body.
    say "Kept sla_get_spent: the normalized history-date function is compatible with earlier schemas"
  end
end
