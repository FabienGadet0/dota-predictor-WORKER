import pandas as pd


def apply_weight_sum_model(df, with_ban, custom_cols=[]):
    if custom_cols == []:
        if with_ban:
            custom_cols = ['winrate', 'pro_ban', 'pro_pick']
        else:
            custom_cols = ['winrate',  'games']
    if with_ban:
        weights = pd.DataFrame(
            pd.Series([0.7, 0.05, 0.25], index=custom_cols, name=0))
    else:
        weights = pd.DataFrame(
            pd.Series([0.75,  0.25], index=custom_cols, name=0))
    return (df.dot(weights))
