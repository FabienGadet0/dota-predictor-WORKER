select
    t.*,
    g.winner
from
    technical_data t
    inner join games g on g.match_id = t.match_id
    and g.start_date > CURRENT_DATE - INTERVAL '7 day'