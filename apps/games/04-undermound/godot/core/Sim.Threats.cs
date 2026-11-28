using System;

namespace Undermound.Core;

/// <summary>The wolf spider: hunts foragers on the surface; soldiers and brave workers fight back.</summary>
public sealed partial class Sim
{
    private float _spiderTimer;

    public bool SpiderAbout => Spiders.Exists(s => !s.Gone && s.State != SpiderState.Leaving);

    private void UpdateSpiders(float dt)
    {
        if (Season != Season.Winter && Ants.Count > 0 && AutoWeather)
        {
            _spiderTimer -= dt;
            if (_spiderTimer <= 0)
            {
                _spiderTimer = _rng.Range(SimConfig.SpiderMinGapSeconds, SimConfig.SpiderMaxGapSeconds);
                if (!SpiderAbout) SpawnSpider();
            }
        }
        foreach (var s in Spiders) UpdateSpider(s, dt);
        Spiders.RemoveAll(s => s.Gone);
    }

    public Spider SpawnSpider(float? x = null)
    {
        var s = new Spider { X = x ?? (_rng.Chance(0.5f) ? 1f : World.Width - 2f) };
        s.Dir = s.X < World.Width / 2f ? 1 : -1;
        Spiders.Add(s);
        Say("A wolf spider is hunting near the nest! Soldiers will defend the entrance.");
        return s;
    }

    private void RaiseAlarm(float x, float amount)
    {
        int cx = (int)x;
        for (int k = -3; k <= 3; k++)
        {
            int nx = cx + k;
            if (nx >= 0 && nx < World.Width) World.Alarm[nx] = MathF.Max(World.Alarm[nx], amount * (1f - MathF.Abs(k) / 4f));
        }
    }

    private static bool InReach(Ant a, World w, float x) =>
        w.Y(a.Cell) == 0 && !a.Grabbed && a.Job != AntJob.Flying && MathF.Abs(w.X(a.Cell) + 0.5f - x) <= 1.1f;

    private void UpdateSpider(Spider s, float dt)
    {
        s.Age += dt;
        s.Timer += dt;

        // Bites from ants in reach; the spider strikes back at one soldier.
        float bites = 0;
        Ant? soldier = null;
        foreach (var a in Ants)
        {
            if (a.Dead || !InReach(a, World, s.X)) continue;
            if (a.Caste == Caste.Soldier) { bites += SimConfig.SoldierBitePerSecond; soldier ??= a; }
            else if (a.Id != s.PreyId) bites += SimConfig.WorkerBitePerSecond;
        }
        s.Fighting = soldier != null;
        if (bites > 0)
        {
            s.Hp -= bites * dt;
            RaiseAlarm(s.X, 2f);
        }
        if (soldier != null)
        {
            soldier.Hp -= SimConfig.SpiderDamagePerSecond * dt;
            if (soldier.Hp <= 0) Kill(soldier, "A soldier died fighting the spider.");
        }

        if (s.Hp <= 0)
        {
            s.Gone = true;
            ReleasePrey(s);
            SpidersDrivenOff++;
            Say("The soldiers killed the wolf spider! Its body is food for the colony.");
            World.Food.Add(new FoodSource { X = Math.Clamp(s.X, 2, World.Width - 3), Amount = 60, Max = 60, Kind = FoodKind.Insect });
            return;
        }
        if (s.State != SpiderState.Leaving)
        {
            bool hurt = s.Hp < SimConfig.SpiderHp * SimConfig.SpiderFleeHp;
            if (hurt || s.Age > SimConfig.SpiderMaxStay || s.Kills >= SimConfig.SpiderMeals)
            {
                s.State = SpiderState.Leaving;
                ReleasePrey(s);
                if (hurt) { SpidersDrivenOff++; Say("The wolf spider retreats, bitten by soldiers."); }
                else Say("The wolf spider wanders off.");
            }
        }

        switch (s.State)
        {
            case SpiderState.Hunting: Hunt(s, dt); break;
            case SpiderState.Eating:
                if (s.Timer >= SimConfig.SpiderEatSeconds) { s.State = SpiderState.Hunting; s.Timer = 0; }
                break;
            case SpiderState.Leaving:
                s.Dir = s.X < World.Width / 2f ? -1 : 1;
                s.X += s.Dir * SimConfig.SpiderSpeed * 0.8f * dt;
                if (s.X <= 0 || s.X >= World.Width - 1) s.Gone = true;
                break;
        }
    }

    private void Hunt(Spider s, float dt)
    {
        if (s.PreyId >= 0)
        {
            var held = FindAnt(s.PreyId);
            if (held == null || held.Dead) { s.PreyId = -1; return; }
            if (s.Timer < SimConfig.SpiderKillSeconds) return;
            held.Grabbed = false;
            Kill(held, "A wolf spider caught an ant.");
            s.PreyId = -1;
            s.Kills++;
            s.State = SpiderState.Eating;
            s.Timer = 0;
            RaiseAlarm(s.X, 3f);
            return;
        }

        // Chase the nearest ant on the surface, workers before soldiers.
        Ant? prey = null;
        float best = SimConfig.SpiderSight;
        foreach (var a in Ants)
        {
            if (a.Dead || a.Grabbed || World.Y(a.Cell) != 0 || a.Job == AntJob.Flying) continue;
            float d = MathF.Abs(World.X(a.Cell) + 0.5f - s.X) + (a.Caste == Caste.Soldier ? 8 : 0);
            if (d < best) { best = d; prey = a; }
        }
        float targetX;
        if (prey != null) targetX = World.X(prey.Cell) + 0.5f;
        else
        {
            // Nobody outside: lurk a few steps from the nearest entrance.
            int o = NearestOpening((int)s.X);
            targetX = o < 0 ? s.X : o + (s.X < o ? -4 : 4);
        }
        float d0 = targetX - s.X;
        if (MathF.Abs(d0) > 0.05f)
        {
            s.Dir = Math.Sign(d0);
            s.X += s.Dir * MathF.Min(MathF.Abs(d0), SimConfig.SpiderSpeed * dt);
        }
        if (prey != null && MathF.Abs(World.X(prey.Cell) + 0.5f - s.X) < 0.7f)
        {
            prey.Grabbed = true;
            prey.Next = -1;
            prey.T = 0;
            s.PreyId = prey.Id;
            s.Timer = 0;
            RaiseAlarm(s.X, 3f);
        }
    }

    private void ReleasePrey(Spider s)
    {
        if (s.PreyId < 0) return;
        var a = FindAnt(s.PreyId);
        if (a != null) a.Grabbed = false;
        s.PreyId = -1;
    }
}
