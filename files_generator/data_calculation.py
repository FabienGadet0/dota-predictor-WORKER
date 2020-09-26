import numpy as np
from logger import log
import pandas as pd
from utils import apply_weight_sum_model
from statistics import mean


def players_peers(players_ids):
    all_players_peers = pd.read_csv(
        './data/all_players_peers.csv')
    scores = []
    wsm_scores = []
    for player_id in players_ids:
        m = all_players_peers[(all_players_peers.account_id == player_id) &
                              (all_players_peers.with_account_id.isin(players_ids))]
        if not m.empty:
            scores.append(np.nanmean(m.winrate))
            wsm_scores.append(np.round(np.nanmean(apply_weight_sum_model(
                m[['winrate', 'games']], with_ban=False)), 4))
    if len(scores) != 0 and len(wsm_scores) != 0:
        return np.round(np.nanmean(scores), 4),  np.round(np.nanmean(wsm_scores), 4)
    return np.nan, np.nan


def players_heroes_synergy(players_ids, team_heroes_id):
    all_players_w_heroes_synergy = pd.read_csv(
        './data/all_players_w_heroes_synergy.csv')
    scores = []
    wsm_scores = []
    for player_id in players_ids:
        m = all_players_w_heroes_synergy[(all_players_w_heroes_synergy.account_id == player_id) &
                                         (all_players_w_heroes_synergy.hero_id.isin(team_heroes_id))]
        if not m.empty:
            scores.append(np.nanmean(m.winrate))
            wsm_scores.append(np.round(np.nanmean(apply_weight_sum_model(
                m[['winrate', 'games']], with_ban=False)), 4))
    if len(scores) != 0 and len(wsm_scores) != 0:
        return np.round(np.nanmean(scores), 4),  np.round(np.nanmean(wsm_scores), 4)
    return np.nan, np.nan


def heroes_matchup(team_1_heroes, team_2_heroes):
    all_matchups = pd.read_csv('./data/all_matchups.csv')
    t1_scores, t2_scores = [], []
    t1_wsm_scores, t2_wsm_scores = [], []
    for t1_hero in team_1_heroes:
        m = all_matchups[(all_matchups.hero_id == t1_hero) &
                         (all_matchups.against_hero_id.isin(team_2_heroes))]
        t1_scores.append(np.nanmean(m.winrate))
        t1_wsm_scores.append(np.round(np.nanmean(apply_weight_sum_model(
            m[['winrate', 'games_played']], custom_cols=['winrate', 'games_played'], with_ban=False)), 4))
    for t2_hero in team_2_heroes:
        m = all_matchups[(all_matchups.hero_id == t2_hero) &
                         (all_matchups.against_hero_id.isin(team_1_heroes))]
        t2_scores.append(np.nanmean(m.winrate))
        t2_wsm_scores.append(np.round(np.nanmean(apply_weight_sum_model(
            m[['winrate', 'games_played']], custom_cols=['winrate', 'games_played'], with_ban=False)), 4))
    if len(t1_scores) != 0 and len(t2_wsm_scores) != 0:
        return np.round(np.nanmean(t1_scores), 4), np.round(np.nanmean(t1_wsm_scores), 4), np.round(np.nanmean(t2_scores), 4), np.round(np.nanmean(t2_wsm_scores), 4)
    return np.nan, np.nan, np.nan, np.nan


def heroes_matchup_stratz(team_1_heroes, team_2_heroes):
    all_matchups = pd.read_csv('./data/all_matchups_stratz.csv')

    t1_synergy_against, t1_winrate_against = all_matchups[(all_matchups['heroId1'].isin(team_1_heroes)) &
                                                          (all_matchups['heroId2'].isin(team_2_heroes))][['synergy_against', 'winrate_against']].mean()

    t1_synergy_with, t1_winrate_with = all_matchups[(all_matchups['heroId1'].isin(team_1_heroes)) &
                                                    (all_matchups['heroId2'].isin(team_1_heroes))][['synergy_with', 'winrate_with']].mean()

    t2_synergy_against, t2_winrate_against = all_matchups[(all_matchups['heroId1'].isin(team_2_heroes)) &
                                                          (all_matchups['heroId2'].isin(team_1_heroes))][['synergy_against', 'winrate_against']].mean()

    t2_synergy_with, t2_winrate_with = all_matchups[(all_matchups['heroId1'].isin(team_2_heroes)) &
                                                    (all_matchups['heroId2'].isin(team_2_heroes))][['synergy_with', 'winrate_with']].mean()

    return np.round(t1_synergy_against,2), np.round(t1_winrate_against,2), np.round(t1_synergy_with,2), np.round(t1_winrate_with,2), np.round(t2_synergy_against,2), np.round(t2_winrate_against,2), np.round(t2_synergy_with,2), np.round(t2_winrate_with,2)
