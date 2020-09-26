import numpy as np
import pandas as pd

from logger import log
from utils import apply_weight_sum_model


class Team():
    def __init__(self, df, players):
        self.overall_winrate = np.nan
        self.overall_wsm_winrate = np.nan
        self.name = 'no name set'
        self.side = ''
        self.team_id = ''
        self.rating = np.nan
        self.players = players
        self.heroes_meta_points = np.nan
        self.matchup_score = np.nan
        self.matchup_wsm_score = np.nan
        self.synergy_score = np.nan
        self.synergy_wsm_score = np.nan
        self.parse_df(df)
        if 'team_id' in self.__dict__:
            self.parse_file()
        self.compute_heroes_with_meta()

    def parse_df(self, df):
        keys = df.keys()
        for key in keys:
            if key in ['name', 'team_name']:
                self.name = df[key]
            elif type(df[key]) == str:
                self.__dict__[key] = df[key].strip("'")
            else:
                self.__dict__[key] = df[key]

    def parse_file(self):
        data = pd.read_csv('./data/all_teams.csv')
        data = data[data['team_id'] == self.team_id]
        if data.empty:
            log('WARNING', 'cannot find more informations about the team')
        else:
            keys = data.keys()
            for key in keys:
                # if key not in self.__dict__:
                self.__dict__[key] = data[key].values[0]
            data['games_played'] = (int(data['wins']) + int(data['losses']))
            data['winrate'] = np.round(
                (data['wins'] / data['games_played']) * 100, 4).values[0]
            self.overall_winrate = data['winrate'].values[0]
            self.overall_wsm_winrate = np.round(apply_weight_sum_model(
                data[['winrate', 'games_played']], custom_cols=['winrate', 'games_played'], with_ban=False).values.mean(), 4)

    def get_indice_heroes(self):
        """Generate top_20_heroes.

        Take top 20 heroes and sum their ratings.
        """
        pass

    def compute_heroes_synergies_with_players(self):
        """For each heroes keep highest : (For each player get indice for this hero).
        """
        pass

    def compute_heroes_with_meta(self, id_name='hero_id'):
        heroes = self.players[id_name]
        heroes_meta = pd.read_csv('./data/all_heroes.csv')
        picked_heroes = heroes_meta[heroes_meta['id'].isin(heroes)].copy()
        picked_heroes['winrate'] = picked_heroes['pro_win'] / \
            picked_heroes['pro_pick']
        self.heroes_meta_points = np.round(picked_heroes.pro_winrate.mean(), 4)
        self.heroes_meta_wsm_points = np.round(apply_weight_sum_model(
            picked_heroes[['winrate', 'pro_ban', 'pro_pick']], with_ban=True).values.mean(), 4)

    def __str__(self):
        return f"{self.name}"  # => winrate of {self.overall_winrate}%"

    def __repr__(self):
        return self.__str__()
