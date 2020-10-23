select
    t.*,
    g.winner,
    g.winner_name
from
    technical_data t
    inner join games g on g.match_id = t.match_id
where
    t.match_id not in (
        select
            match_id
        from
            prediction
        where
            predict_name is not null
    )
    and g.start_date > '2020-10-15'