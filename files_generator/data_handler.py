"""Manage data"""
import pandas as pd
from datetime import datetime


def make_dataset(df, is_prediction, additional_values=[]):
    dataset = pd.DataFrame()
    for _, game in df.iterrows():
        tmp = pd.Series()
        if 'team_name' in game.dire_team.__dict__:
            tmp['dire_team'] = repr(str(game.dire_team.team_name).strip("'"))
        elif 'name' in game.dire_team.__dict__:
            tmp['dire_team'] = repr(str(game.dire_team.name).strip("'"))

        if 'team_name' in game.radiant_team.__dict__:
            tmp['radiant_team'] = repr(
                str(game.radiant_team.team_name).strip("'"))
        elif 'name' in game.radiant_team.__dict__:
            tmp['radiant_team'] = repr(str(game.radiant_team.name).strip("'"))

        tmp['match_id'] = int(game.match_id)
        if is_prediction:
            tmp['last_update_time'] = game.last_update_time
        else:
            tmp['winner'] = game.winner
            tmp['patch'] = game.version
        try :
            tmp['start_time'] = str(datetime.fromtimestamp(game['start_time']))
        except KeyError:
            tmp['last_update_time'] = game['last_update_time']
        
        for optional_value in additional_values:
            if (optional_value in game.keys()):
                tmp[optional_value] = game[optional_value]

        tmp['dire_team_heroes_meta_points'] = game.dire_team.heroes_meta_points
        tmp['dire_team_matchup_score'] = game.dire_team.matchup_score
        tmp['dire_team_synergy_with'] = game.dire_team.synergy_with
        tmp['dire_team_synergy_against'] = game.dire_team.synergy_against
        tmp['dire_team_winrate_with'] = game.dire_team.winrate_with
        tmp['dire_team_winrate_against'] = game.dire_team.winrate_against
        tmp['dire_team_synergy_score'] = game.dire_team.synergy_score
        tmp['dire_team_peers_score'] = game.dire_team.peers_score
        tmp['dire_team_rating'] = game.dire_team.rating
        tmp['dire_team_winrate'] = game.dire_team.overall_winrate

        tmp['radiant_team_heroes_meta_points'] = game.radiant_team.heroes_meta_points
        tmp['radiant_team_matchup_score'] = game.radiant_team.matchup_score
        tmp['radiant_team_synergy_with'] = game.radiant_team.synergy_with
        tmp['radiant_team_synergy_against'] = game.radiant_team.synergy_against
        tmp['radiant_team_winrate_with'] = game.radiant_team.winrate_with
        tmp['radiant_team_winrate_against'] = game.radiant_team.winrate_against
        tmp['radiant_team_synergy_score'] = game.radiant_team.synergy_score
        tmp['radiant_team_peers_score'] = game.radiant_team.peers_score
        tmp['radiant_team_rating'] = game.radiant_team.rating
        tmp['radiant_team_winrate'] = game.radiant_team.overall_winrate

        dataset = dataset.append(tmp, ignore_index=True)
    if not dataset.empty:
        if is_prediction:
            return dataset[['match_id',  'dire_team', 'dire_team_heroes_meta_points',
                             'dire_team_matchup_score', 'dire_team_synergy_with', 'dire_team_synergy_against', 'dire_team_winrate_with', 'dire_team_winrate_against',
                              'dire_team_synergy_score',  'dire_team_rating', 'dire_team_winrate',
                             'radiant_team',
                            'radiant_team_heroes_meta_points',
                             'radiant_team_matchup_score', 'radiant_team_synergy_with', 'radiant_team_synergy_against', 'radiant_team_winrate_with', 'radiant_team_winrate_against',
                            'radiant_team_synergy_score',  'radiant_team_rating',
                            'radiant_team_winrate',  'last_update_time', 'radiant_team_peers_score',  'dire_team_peers_score']]
        dataset["source"] = "openDota"
        return dataset[['match_id', 'start_time','winner', 'patch', 'dire_team', 'dire_team_heroes_meta_points',
                         'dire_team_matchup_score', 'dire_team_synergy_with', 'dire_team_synergy_against', 'dire_team_winrate_with', 'dire_team_winrate_against',
                         'dire_team_synergy_score',  'dire_team_rating', 'dire_team_winrate',
                         'radiant_team',
                        'radiant_team_heroes_meta_points',
                         'radiant_team_matchup_score', 'radiant_team_synergy_with', 'radiant_team_synergy_against', 'radiant_team_winrate_with', 'radiant_team_winrate_against',
                         'radiant_team_synergy_score',  'radiant_team_rating',
                        'radiant_team_winrate',   'radiant_team_peers_score',  'dire_team_peers_score',  'game_mode', 'dire_score', 'radiant_score', 'duration', 'first_blood_time']]
    return pd.DataFrame()
