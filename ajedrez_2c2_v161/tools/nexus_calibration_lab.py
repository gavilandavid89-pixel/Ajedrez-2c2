#!/usr/bin/env python3
"""NEXUS calibration lab: consumes anonymized JSONL telemetry from production.
No network access is required. The same script can be used on exported batches.
"""
import argparse, json, math, statistics
from collections import defaultdict


def load(path):
    rows=[]
    with open(path, encoding='utf-8') as f:
        for line in f:
            line=line.strip()
            if not line: continue
            x=json.loads(line)
            if x.get('event_type')=='competitive_match_result': rows.append(x)
    return rows


def brier(rows):
    return statistics.fmean((float(r.get('expected',.5)) - (1.0 if r.get('outcome')=='win' else 0.0 if r.get('outcome')=='loss' else .5))**2 for r in rows)


def logloss(rows):
    vals=[]
    for r in rows:
        p=min(.999999,max(.000001,float(r.get('expected',.5))))
        y=1.0 if r.get('outcome')=='win' else 0.0 if r.get('outcome')=='loss' else .5
        vals.append(-(y*math.log(p)+(1-y)*math.log(1-p)))
    return statistics.fmean(vals)


def calibration(rows, bins=10):
    groups=defaultdict(list)
    for r in rows:
        p=min(.999999,max(.000001,float(r.get('expected',.5))))
        y=1.0 if r.get('outcome')=='win' else 0.0 if r.get('outcome')=='loss' else .5
        groups[min(bins-1,int(p*bins))].append((p,y))
    weighted=0.0
    for vals in groups.values():
        if not vals: continue
        weighted += len(vals)/len(rows)*abs(statistics.fmean(p for p,_ in vals)-statistics.fmean(y for _,y in vals))
    return weighted


def report(rows):
    if not rows:
        return {'matches':0}
    out={'matches':len(rows),'brier':brier(rows),'logloss':logloss(rows),'calibration_error':calibration(rows),
         'avg_surprise':statistics.fmean(float(r.get('surprise',0)) for r in rows),
         'avg_uncertainty_before':statistics.fmean(float(r.get('uncertainty_before',0)) for r in rows),
         'avg_uncertainty_after':statistics.fmean(float(r.get('uncertainty_after',0)) for r in rows)}
    modes=defaultdict(list); bots=defaultdict(list); gaps=defaultdict(list)
    for r in rows:
        modes[r.get('mode','?')].append(r)
        if r.get('bot_id'): bots[r['bot_id']].append(r)
        gap=abs(int(r.get('opponent_rating_before',1000))-int(r.get('rating_before',1000)))
        bucket='0-99' if gap<100 else '100-249' if gap<250 else '250-499' if gap<500 else '500+'
        gaps[bucket].append(r)
    out['modes']={k:len(v) for k,v in modes.items()}
    out['bot_matches']={k:len(v) for k,v in bots.items()}
    out['rating_gap_samples']={k:len(v) for k,v in gaps.items()}
    return out


def main():
    ap=argparse.ArgumentParser(); ap.add_argument('jsonl'); ap.add_argument('--pretty',action='store_true'); args=ap.parse_args()
    rows=load(args.jsonl); data=report(rows)
    print(json.dumps(data,ensure_ascii=False,indent=2 if args.pretty else None))

if __name__=='__main__': main()
