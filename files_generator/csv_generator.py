from datetime import datetime, timedelta
from statistics import mean

import numpy as np
import pandas as pd
import os
import data_calculation as data_calculation
import data_handler as data_handler
from api_handler import Api_handler
from logger import log
from team import Team
import requests
from os import path
from multiprocessing import Pool


class Csv_generator(Api_handler):
    def __init__(self, api_type):
        super().__init__(api_type)

    def generate_meta(self):
        all_func = [self.generate_teams, self.generate_heroes_meta,
                    self.generate_heroes_matchups, self.generate_heroes_matchups_from_stratz, self.generate_players_w_heroes_synergy, self.generate_players_peers]
        # all_func = [self.generate_players_w_heroes_synergy, self.generate_players_peers, self.generate_teams, self.generate_heroes_meta,self.generate_heroes_matchups,self.generate_heroes_matchups_from_stratz]
        pool = Pool(len(all_func))
        for func in all_func:
            pool.apply_async(func)
        pool.close()
        pool.join()
        return ('OK')

    def generate_players_w_heroes_synergy(self):
        all_players = pd.DataFrame(self.raw_query(
            'proPlayers/'))
        all_players = all_players[['account_id',
                                   'country_code', 'name', 'team_id', 'team_name', 'is_pro']]
        all_heroes_per_player = pd.DataFrame()
        accounts_ids = all_players.account_id.values
        log('INFO', f'Compute synergy for {len(accounts_ids)} players')
        # ? Get heroes for each players
        for account_id in accounts_ids:
            try:
                heroes = pd.DataFrame(self.raw_query(
                    f'players/{account_id}/heroes?having=50'))
                heroes['last_played'] = heroes['last_played'].apply(
                    lambda x: datetime.fromtimestamp(x))

                heroes['winrate'] = np.round(
                    (heroes['win'] / heroes['games']) * 100, 4)

                heroes['account_id'] = account_id
                all_heroes_per_player = all_heroes_per_player.append(
                    heroes, ignore_index=True)
            except:
                pass

        df = all_players.merge(all_heroes_per_player, on='account_id')
        df.to_csv('data/all_players_w_heroes_synergy.csv')

    def generate_players_peers(self):
        all_players = pd.DataFrame(self.raw_query(
            'proPlayers/'))
        all_players = all_players[['account_id',
                                   'country_code', 'name', 'team_id', 'team_name', 'is_pro']]
        all_players_peers = pd.DataFrame()
        accounts_ids = all_players.account_id.values
        log('INFO', f'Compute players peers for {len(accounts_ids)} players')
        # ? Get peers for each players
        for account_id in accounts_ids:
            try:
                peers = pd.DataFrame(self.raw_query(
                    f'players/{account_id}/peers?having=50'))
                peers['last_played'] = peers['last_played'].apply(
                    lambda x: datetime.fromtimestamp(x))

                peers['winrate'] = np.round(
                    (peers['win'] / peers['games']) * 100, 4)
                peers['with_account_id'] = peers['account_id']
                peers['account_id'] = account_id
                all_players_peers = all_players_peers.append(
                    peers, ignore_index=True)
            except:
                pass

        df = all_players.merge(all_players_peers, on='account_id')
        df.drop(['with_gpm_sum', 'with_xpm_sum', 'personaname', 'is_contributor',
                 'last_login', 'avatar', 'avatarfull'], axis=1, errors='ignore').to_csv('data/all_players_peers.csv')

    def generate_heroes_matchups_from_stratz(self):
        log('INFO', 'Compute synergies with stratz API')
        all_heroes = pd.read_csv('./data/all_heroes.csv')
        all_matchups = pd.DataFrame()
        for id in all_heroes.id.values:
            try:
                log('INFO',
                    f"Request https://api.stratz.com/api/v1/Hero/{id}/matchUp")
                r = requests.get(
                    f'https://api.stratz.com/api/v1/Hero/{id}/matchUp').json()
                df_with = pd.DataFrame(r['advantage'][0]['with'])[
                    ['heroId1', 'heroId2', 'synergy', 'wins']].rename(columns={"synergy": "synergy_with", "wins": "winrate_with"})
                df_vs = pd.DataFrame(r['advantage'][0]['vs'])[
                    ['heroId1', 'heroId2', 'synergy', 'wins']].rename(columns={"synergy": "synergy_against", "wins": "winrate_against"})
                df_synergies = df_with.merge(df_vs, on=['heroId1', 'heroId2'])
                all_matchups = all_matchups.append(df_synergies)
            except:
                pass
        all_matchups.to_csv('./data/all_matchups_stratz.csv')
        log('FILE', 'Synergies finished , saved to ./data/all_matchups_stratz.csv')

    def generate_heroes_matchups(self):
        all_heroes = pd.read_csv('./data/all_heroes.csv')
        all_matchups = pd.DataFrame()
        for id in all_heroes.id.values:
            try:
                df = pd.DataFrame(self.raw_query(f"heroes/{id}/matchups"))
                df['winrate'] = np.round(df['wins'] / df['games_played'], 4)
                df['against_hero_id'] = df['hero_id']
                df['hero_id'] = id
                all_matchups = all_matchups.append(df)
            except:
                pass
                # log('DEBUG', "Cannot get matchup " + ValueError)
        all_matchups.to_csv('./data/all_matchups.csv')

    def generate_heroes_meta(self):
        df = pd.DataFrame(self.raw_query("heroStats/")
                          )[['id', 'localized_name', 'icon', 'pro_ban', 'pro_win', 'pro_pick']]
        df['pro_winrate'] = np.round((df['pro_win'] / df['pro_pick']) * 100, 4)
        df.to_csv('./data/all_heroes.csv', index=False)

    def generate_teams(self):
        pd.DataFrame(self.raw_query("teams/")
                     ).to_csv('./data/all_teams.csv', index=False)

    def generate_matches(self, days_ago=5, amount_to_scrap=0, start_at_match_id=0):
        if amount_to_scrap == 0:
            amount_to_scrap = days_ago * 100
        if start_at_match_id != 0:
            df = pd.DataFrame(self.exec_query(
                additional=f'?less_than_match_id={start_at_match_id}'))
        else:
            df = pd.DataFrame(self.exec_query())

        df.to_csv('./data/all_matches.csv', index=False)
        for _ in range(0, int((amount_to_scrap - 100) / 100)):
            try:
                df = df.append(pd.DataFrame(self.exec_query(
                    additional=f"?less_than_match_id={df.match_id.iloc[-1]}")))
            except:
                pass
        df['start_time'] = df['start_time'].apply(
            lambda x: datetime.fromtimestamp(x))
        df[df['start_time'] > (datetime.now() - timedelta(days=days_ago))
           ].to_csv('./data/all_matches.csv', index=False)
        os.environ["NB_QUERY_DONE"] = str(self.nb_query_done)

    def process_matches(self, number_of_match_to_process=0, mode='a+'):
        df = pd.read_csv('./data/all_matches.csv')
        dataset_size = 0

        if number_of_match_to_process == 0:
            number_of_match_to_process = len(df)

        log('INFO', f'Processing {number_of_match_to_process} matches')
        step = number_of_match_to_process if number_of_match_to_process < 100 else 100
        while (not df.empty):
            ready_for_dataset = self.process_batch(df[0:step].match_id)
            df = df.iloc[step:]
            ready_for_dataset["source"] = "openDota"
            data_chunk = data_handler.make_dataset(
                ready_for_dataset, is_prediction=False, additional_values=['patch',
                                                                           'game_mode',  'source', 'dire_score', 'radiant_score', 'duration', 'first_blood_time'])
            dataset_size += len(data_chunk)
            if not data_chunk.empty:
                # log('SUCCESS', f"{len(data_chunk)}/{dataset_size} into file ")
                data_chunk['match_id'] = data_chunk['match_id'].astype(int)
                data_chunk.to_csv('data/dataset.csv', mode=mode,
                                  header=(not mode == 'a+'), index=False)
                mode = 'a+'
            if dataset_size >= number_of_match_to_process:
                os.environ["NB_QUERY_DONE"] = str(self.nb_query_done)
                return dataset_size
        os.environ["NB_QUERY_DONE"] = str(self.nb_query_done)
        return dataset_size

    def clean_processed_matches(self):
        # log('INFO', 'Cleaning all_matches.csv and files /dataset.csv')
        row_nb_last_match = 0
        df = pd.read_csv('./data/dataset.csv')
        matches = pd.read_csv(
            './data/all_matches.csv').drop_duplicates()
        i = matches[matches.match_id == df.iloc[-1].match_id].index
        if not i.empty:
            row_nb_last_match = (i.values[0]) + 1
        else:
            log('WAR', 'Nothing to clean.')
            return
        if row_nb_last_match > 0:
            matches = matches[row_nb_last_match:]
        matches.to_csv('./data/all_matches.csv', index=False)
        df.drop_duplicates(subset="match_id").to_csv(
            './data/dataset.csv', index=False)
        os.environ["NB_QUERY_DONE"] = str(self.nb_query_done)

    def process_batch(self, match_ids):
        matches = pd.DataFrame()
        preprocess = pd.Series()
        for match_id in match_ids:
            try:
                r = self.raw_query(f"matches/{match_id}")
                if r != [{}]:
                    data = pd.Series(r)[['match_id', 'game_mode', 'human_players',
                                         'version']]
                    # ? Check if these columns exist.
                    if set(['radiant_team', 'dire_team', 'radiant_win']).issubset(pd.Series(r).keys()):
                        preprocess = pd.Series(
                            r)[['radiant_team', 'dire_team', 'radiant_win']]

                    players = pd.DataFrame(r['players'])[
                        ["account_id", 'isRadiant', 'hero_id']]

                    data['winner'] = 'radiant_team' if preprocess['radiant_win'] else 'dire_team'

                    # ? Fill teams
                    log('DEBUG', 'Fill teams class')
                    data['radiant_team'] = Team(preprocess['radiant_team'],
                                                players[players['isRadiant']])
                    data['dire_team'] = Team(preprocess['dire_team'],
                                             players[players['isRadiant'] == False])
                    # ? ===================

                    # ? Synergy scores
                    log('DEBUG', 'Compute players heroes synergy')
                    data['radiant_team'].synergy_score, data['radiant_team'].synergy_wsm_score = data_calculation.players_heroes_synergy(
                        data.radiant_team.players.account_id, data.radiant_team.players.hero_id)
                    data['dire_team'].synergy_score, data['dire_team'].synergy_wsm_score = data_calculation.players_heroes_synergy(
                        data.dire_team.players.account_id, data.dire_team.players.hero_id)
                    # ? ===================

                    # ? Players peers scores
                    log('DEBUG', 'Compute players heroes synergy')
                    data['radiant_team'].peers_score, data['radiant_team'].peers_wsm_score = data_calculation.players_peers(
                        data.radiant_team.players.account_id)
                    data['dire_team'].peers_score, data['dire_team'].peers_wsm_score = data_calculation.players_peers(
                        data.dire_team.players.account_id)
                    # ? ===================

                    # ? Matchup scores
                    log('DEBUG', 'Compute heroes matchup scores')
                    data['radiant_team'].matchup_score, data['radiant_team'].matchup_wsm_score, data['dire_team'].matchup_score, data['dire_team'].matchup_wsm_score = data_calculation.heroes_matchup(
                        (data.radiant_team.players.hero_id), (data.dire_team.players.hero_id))
                    # ? ===================

                    # ? Matchup scores stratz
                    log('DEBUG', 'Compute heroes matchup scores')
                    data['radiant_team'].synergy_against, data['radiant_team'].winrate_against, data['radiant_team'].synergy_with, data['radiant_team'].winrate_with, data['dire_team'].synergy_against, data['dire_team'].winrate_against, data['dire_team'].synergy_with, data['dire_team'].winrate_with, = data_calculation.heroes_matchup_stratz(
                        (data.radiant_team.players.hero_id), (data.dire_team.players.hero_id))
                    # ? ===================

                    # ? Misc data
                    c = pd.Series(
                        r)[['replay_url', 'patch', 'start_time', 'game_mode', 'dire_score', 'radiant_score', 'duration', 'first_blood_time']]
                    data['replay_url'] = c['replay_url']
                    data['first_blood_time'] = c['first_blood_time']
                    data['radiant_score'] = int(c['radiant_score'])
                    data['duration'] = int(c['duration'])
                    data['dire_score'] = int(c['dire_score'])
                    data['patch'] = c['patch']
                    data['start_time'] = c['start_time']
                    data['game_mode'] = c['game_mode']

                    if len(preprocess['radiant_team']) > 1 and len(preprocess['dire_team']) > 1 and len(players) == 10:
                        matches = matches.append(data, ignore_index=True)
                        log('DEBUG', f'New line appended {data.match_id}')
                    else:
                        log('DEBUG', f'match {match_id} incomplete')
            except:
                pass
        return matches


def generate_games(days_ago=5, to_scrap=0, start_at_match_id=0):
    c = Csv_generator('proMatches')
    c.generate_matches(days_ago=days_ago,
                       start_at_match_id=start_at_match_id)
    mode = 'w+'
    # ? To generate big file and not delete old one (if not inserted to db)
    # if path.exists("./data/dataset.csv"):
    #     mode = 'a+'
    if path.exists("./data/dataset.csv"):
        os.remove("./data/dataset.csv")

    ret = c.process_matches(number_of_match_to_process=to_scrap, mode=mode)
    if ret == 0:
        log("INFO", "nothing to do")
    else:
        c.clean_processed_matches()


def generate_meta():
    l = Csv_generator(api_type='proMatches')
    l.generate_meta()
