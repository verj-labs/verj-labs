using System;

namespace Undermound.Core;

/// <summary>What every ant does each tick: move, then decide its next step from its job.</summary>
public sealed partial class Sim
{
    private int _diggers, _foragers, _nursesAssigned, _workers;

    private void CountJobs()
    {
        _diggers = _foragers = _nursesAssigned = _nurses = _workers = 0;
        foreach (var a in Ants)
        {
            if (a.Caste != Caste.Worker) continue;
            _workers++;
            switch (a.Job)
            {
                case AntJob.ToDig or AntJob.Digging: _diggers++; break;
                case AntJob.ForageOut or AntJob.CarryFood or AntJob.ReturnHome: _foragers++; break;
                case AntJob.Nursing:
                    _nursesAssigned++;
                    if (ToNursery.Dist[a.Cell] == 0) _nurses++;
                    break;
            }
        }
    }

    private void Kill(Ant a, string message)
    {
        if (a.Dead) return;
        a.Dead = true;
        WorkersDied++;
        Say(message);
    }

    private void UpdateAnt(Ant a, float dt)
    {
        if (a.Dead || a.Grabbed) return;
        if (a.Job == AntJob.Flying)
        {
            a.Flight += dt;
            if (a.Flight >= SimConfig.FlightSeconds) { a.Dead = true; QueensFlown++; }
            return;
        }

        float temp = TempAt(a.Cell);
        if (temp < SimConfig.FreezeTemp)
        {
            a.Chill += dt;
            if (a.Chill > SimConfig.ChillDeathSeconds) { Kill(a, "An ant froze. Keep the colony deep in winter."); return; }
        }
        else a.Chill = MathF.Max(0, a.Chill - dt);

        float speedMul = ColdFactor(temp);
        if (a.Caste == Caste.Soldier) speedMul *= SimConfig.SoldierSpeedFactor;
        if (World.Water[a.Cell] > 0.6f)
        {
            speedMul *= SimConfig.WaterSpeedFactor;
            a.Submerged += dt;
            if (a.Submerged > SimConfig.DrownSeconds) { Kill(a, "An ant drowned."); return; }
        }
        else a.Submerged = MathF.Max(0, a.Submerged - 2 * dt);

        if (a.Moving)
        {
            bool surface = World.Y(a.Cell) == 0 && World.Y(a.Next) == 0;
            a.T += (surface ? SimConfig.SurfaceSpeed : SimConfig.TunnelSpeed) * speedMul * dt;
            if (a.T < 1f) return;
            a.Cell = a.Next;
            a.Next = -1;
            a.T = 0;
            OnArrive(a);
        }
        Think(a, dt);
    }

    private void OnArrive(Ant a)
    {
        if (World.Y(a.Cell) != 0) return;
        int x = World.X(a.Cell);
        if (a.Carrying == Carry.Food) World.Scent[x] += SimConfig.ScentDeposit;
        if (a.Job == AntJob.ForageOut) a.Travelled++;
    }

    private void Walk(Ant a, int cell)
    {
        a.FacingX = World.X(cell) - World.X(a.Cell);
        a.FacingY = World.Y(cell) - World.Y(a.Cell);
        if (a.FacingX != 0) a.Side = a.FacingX > 0 ? 1 : -1;
        a.Next = cell;
        a.T = 0;
    }

    /// <summary>Step along a field. Returns false when already at a source or cut off.</summary>
    private bool Follow(Ant a, FlowField f)
    {
        int n = f.Next(a.Cell, a.Id);
        if (n < 0) return false;
        // Do not wade from dry ground into deep water; wait at the edge instead.
        if (World.Water[n] > 0.6f && World.Water[a.Cell] <= 0.6f && a.Job is not (AntJob.Fighting or AntJob.ToFlight)) return true;
        Walk(a, n);
        return true;
    }

    private void Think(Ant a, float dt)
    {
        // Standing in deep water, any ant climbs toward the surface until it is dry.
        if (World.Water[a.Cell] > 0.6f && a.Job != AntJob.Fighting && Follow(a, ToSurface)) return;
        switch (a.Job)
        {
            case AntJob.Idle: ChooseJob(a); break;
            case AntJob.ToDig: ThinkToDig(a); break;
            case AntJob.Digging: ThinkDigging(a, dt); break;
            case AntJob.CarrySoil: ThinkCarrySoil(a); break;
            case AntJob.DropSoil: ThinkDropSoil(a); break;
            case AntJob.ForageOut: ThinkForage(a); break;
            case AntJob.CarryFood: ThinkCarryFood(a); break;
            case AntJob.ReturnHome: ThinkReturnHome(a); break;
            case AntJob.Resting: ThinkResting(a, dt); break;
            case AntJob.Nursing: ThinkNursing(a, dt); break;
            case AntJob.Guarding: ThinkGuarding(a, dt); break;
            case AntJob.Fighting: ThinkFighting(a); break;
            case AntJob.AlateWaiting: ThinkAlateWaiting(a); break;
            case AntJob.ToFlight: ThinkToFlight(a); break;
        }
    }

    // ---------- choosing a job ----------

    public bool CanForage => Food < FoodCapacity - 0.5f && Season != Season.Winter
                             && SurfaceTemp >= SimConfig.ForageTemp && !(Raining && !Snowing);

    private void ChooseJob(Ant a)
    {
        if (a.Caste == Caste.Soldier) { a.Job = AntJob.Guarding; return; }
        if (a.Caste == Caste.Alate) { a.Job = FlightUnderway ? AntJob.ToFlight : AntJob.AlateWaiting; return; }

        var p = Priorities;
        float sum = p.Dig + p.Forage + p.Nurse;
        if (sum > 0)
        {
            int frontier = ToDig.SourceCount;
            bool canDig = frontier > 0 && ToDig.Reachable(a.Cell) && p.Dig > 0;
            bool canNurse = Brood.Count > 0 && ToNursery.SourceCount > 0 && ToNursery.Reachable(a.Cell) && p.Nurse > 0;
            int door = NearestOpening(World.X(a.Cell));
            bool canForage = CanForage && p.Forage > 0 && !(door >= 0 && AlarmNear(door, 0));
            int wantDig = canDig ? Math.Clamp((int)MathF.Ceiling(_workers * p.Dig / sum), 1, frontier * SimConfig.DiggersPerFrontierCell) : 0;
            int wantForage = canForage ? Math.Max(1, (int)MathF.Ceiling(_workers * p.Forage / sum)) : 0;
            int wantNurse = canNurse ? Math.Max(1, (int)MathF.Ceiling(_workers * p.Nurse / sum)) : 0;
            int dDig = wantDig - _diggers, dForage = wantForage - _foragers, dNurse = wantNurse - _nursesAssigned;
            if (dDig > 0 && dDig >= dForage && dDig >= dNurse)
            {
                a.Job = AntJob.ToDig;
                _diggers++;
                return;
            }
            if (dForage > 0 && dForage >= dNurse)
            {
                a.Job = AntJob.ForageOut;
                a.Travelled = 0;
                a.Dir = 0;
                _foragers++;
                return;
            }
            if (dNurse > 0)
            {
                a.Job = AntJob.Nursing;
                a.Timer = SimConfig.NurseSeconds;
                _nursesAssigned++;
                return;
            }
        }
        a.Job = AntJob.Resting;
        a.Timer = _rng.Range(SimConfig.RestMinSeconds, SimConfig.RestMaxSeconds);
    }

    // ---------- digging ----------

    private void ThinkToDig(Ant a)
    {
        if (ToDig.Dist[a.Cell] == 0) { a.Job = AntJob.Digging; return; }
        if (!Follow(a, ToDig)) a.Job = AntJob.Idle;
    }

    private void ThinkDigging(Ant a, float dt)
    {
        int target = DigTargetNextTo(a);
        if (target < 0) { a.Job = AntJob.Idle; return; }
        a.FacingX = World.X(target) - World.X(a.Cell);
        a.FacingY = World.Y(target) - World.Y(a.Cell);
        var m = World.Cells[target];
        World.DigProgress[target] += dt * ColdFactor(TempAt(a.Cell)) / (SimConfig.BaseDigSeconds * World.Hardness(m));
        if (World.DigProgress[target] < 1f) return;
        World.DigProgress[target] = 0;
        World.SetDigOrder(target, false);
        World.SetMaterial(target, CellType.Tunnel);
        CellsDug++;
        DugThisTick = true;
        a.Carrying = Carry.Soil;
        a.Job = AntJob.CarrySoil;
    }

    /// <summary>True on ticks when a cell was dug out (the view plays a sound).</summary>
    public bool DugThisTick;

    private int DigTargetNextTo(Ant a)
    {
        int x = World.X(a.Cell), y = World.Y(a.Cell);
        for (int k = 0; k < 4; k++)
        {
            int kk = (k + a.Id) & 3;
            int nx = x + Dx[kk], ny = y + Dy[kk];
            if (!World.InBounds(nx, ny)) continue;
            int n = World.Index(nx, ny);
            if (World.DigOrder[n] && World.IsDiggable(World.Cells[n])) return n;
        }
        return -1;
    }

    private void ThinkCarrySoil(Ant a)
    {
        if (World.Y(a.Cell) == 0)
        {
            int x = World.X(a.Cell);
            int side = _rng.Chance(0.5f) ? 1 : -1;
            a.TargetX = Math.Clamp(x + side * _rng.Range(2, 8), 0, World.Width - 1);
            a.Job = AntJob.DropSoil;
            ThinkDropSoil(a);
            return;
        }
        if (!Follow(a, ToSurface)) a.Job = AntJob.Idle;
    }

    private void ThinkDropSoil(Ant a)
    {
        int x = World.X(a.Cell);
        if (x == a.TargetX)
        {
            World.Mound[x]++;
            a.Carrying = Carry.None;
            a.Job = AntJob.Idle;
            return;
        }
        Walk(a, World.Index(x + Math.Sign(a.TargetX - x), 0));
    }

    // ---------- foraging ----------

    /// <summary>Alarm scent within a few cells (ahead only when dir is not 0).</summary>
    private bool AlarmNear(int x, int dir)
    {
        for (int k = -6; k <= 6; k++)
        {
            if (dir != 0 && Math.Sign(k) != dir) continue;
            int nx = x + k;
            if (nx >= 0 && nx < World.Width && World.Alarm[nx] > SimConfig.AlarmFleeLevel) return true;
        }
        return false;
    }

    private void ThinkForage(Ant a)
    {
        if (World.Y(a.Cell) != 0)
        {
            if (!CanForage) { a.Job = AntJob.Idle; return; }
            if (!Follow(a, ToSurface)) a.Job = AntJob.Idle;
            return;
        }
        int x = World.X(a.Cell);
        if (!CanForage) { a.Job = AntJob.ReturnHome; ThinkReturnHome(a); return; }
        var food = World.FoodAt(x + 0.5f);
        if (food != null)
        {
            food.Amount--;
            a.Carrying = Carry.Food;
            a.Job = AntJob.CarryFood;
            ThinkCarryFood(a);
            return;
        }
        if (a.Travelled > SimConfig.ForageMaxRange || AlarmNear(x, a.Dir))
        {
            a.Job = AntJob.ReturnHome;
            ThinkReturnHome(a);
            return;
        }

        float right = SmellAround(x, 1), left = SmellAround(x, -1);
        if (a.Dir == 0)
        {
            // Just out of the nest: pick the side that smells of food, else a random side.
            bool smell = MathF.Max(left, right) > SimConfig.ScentFollowThreshold;
            a.Dir = smell && _rng.Chance(0.85f) ? (right >= left ? 1 : -1) : (_rng.Chance(0.5f) ? 1 : -1);
        }
        else
        {
            float ahead = a.Dir > 0 ? right : left;
            if (ahead < SimConfig.ScentFollowThreshold && _rng.Chance(SimConfig.RandomTurnChance)) a.Dir = -a.Dir;
        }
        int nx = x + a.Dir;
        if (nx < 0 || nx >= World.Width || World.Avoid[nx])
        {
            a.Dir = -a.Dir;
            nx = x + a.Dir;
            if (nx < 0 || nx >= World.Width || World.Avoid[nx]) { a.Job = AntJob.ReturnHome; ThinkReturnHome(a); return; }
        }
        Walk(a, World.Index(nx, 0));
    }

    /// <summary>Food scent plus the player's painted trail, summed over a few cells to one side.</summary>
    private float SmellAround(int x, int dir)
    {
        float sum = 0;
        for (int k = 1; k <= SimConfig.ScentSenseCells; k++)
        {
            int nx = x + dir * k;
            if (nx < 0 || nx >= World.Width || World.Avoid[nx]) break;
            sum += World.Scent[nx] + World.Guide[nx];
        }
        return sum;
    }

    private FlowField? HomeField()
    {
        if (ToStore.SourceCount > 0) return ToStore;
        if (ToNursery.SourceCount > 0) return ToNursery;
        return null;
    }

    private void ThinkCarryFood(Ant a)
    {
        var home = HomeField();
        if (home == null || home.Dist[a.Cell] == 0 || !home.Reachable(a.Cell))
        {
            if (home != null && home.Reachable(a.Cell) || home == null && World.Y(a.Cell) > 0)
            {
                Food = MathF.Min(FoodCapacity, Food + 1f);
                FoodGathered++;
            }
            a.Carrying = Carry.None;
            a.Job = AntJob.Idle;
            return;
        }
        Follow(a, home);
    }

    private void ThinkReturnHome(Ant a)
    {
        var home = HomeField();
        if (home == null || home.Dist[a.Cell] == 0 || !Follow(a, home))
        {
            a.Job = AntJob.Resting;
            a.Timer = _rng.Range(SimConfig.RestMinSeconds, SimConfig.RestMaxSeconds);
        }
    }

    // ---------- resting and nursing ----------

    private void ThinkResting(Ant a, float dt)
    {
        var field = ToNursery.SourceCount > 0 ? ToNursery : HomeField();
        if (field != null && field.Reachable(a.Cell) && field.Dist[a.Cell] > 0)
        {
            Follow(a, field);
            return;
        }
        a.Timer -= dt;
        if (a.Timer <= 0) { a.Job = AntJob.Idle; return; }
        MillAbout(a, field);
    }

    /// <summary>Wander a step inside the room, now and then.</summary>
    private void MillAbout(Ant a, FlowField? room)
    {
        if (room == null || !_rng.Chance(0.15f)) return;
        int x = World.X(a.Cell), y = World.Y(a.Cell);
        int k = _rng.Range(0, 4);
        int nx = x + Dx[k], ny = y + Dy[k];
        if (World.InBounds(nx, ny) && room.Dist[World.Index(nx, ny)] == 0) Walk(a, World.Index(nx, ny));
    }

    private void ThinkNursing(Ant a, float dt)
    {
        if (Brood.Count == 0 || ToNursery.SourceCount == 0) { a.Job = AntJob.Idle; return; }
        if (ToNursery.Dist[a.Cell] > 0)
        {
            if (!Follow(a, ToNursery)) a.Job = AntJob.Idle;
            return;
        }
        a.Timer -= dt;
        if (a.Timer <= 0) { a.Job = AntJob.Idle; return; }
        // Stay close to the brood pile by the queen.
        int qx = World.X(QueenCell), x = World.X(a.Cell), y = World.Y(a.Cell);
        int step = Math.Sign(qx - x);
        if (Math.Abs(qx - x) > 2 && step != 0)
        {
            int n = World.Index(x + step, y);
            if (ToNursery.Dist[n] == 0) { Walk(a, n); return; }
        }
        MillAbout(a, ToNursery);
    }

    // ---------- soldiers ----------

    private Spider? Threat(int x)
    {
        Spider? best = null;
        float bestD = SimConfig.SpiderSight;
        foreach (var s in Spiders)
        {
            if (s.Gone || s.State == SpiderState.Leaving) continue;
            float d = MathF.Abs(s.X - x);
            if (d < bestD) { bestD = d; best = s; }
        }
        return best;
    }

    private int NearestOpening(int x)
    {
        int best = -1, bestD = int.MaxValue;
        foreach (int o in World.Openings())
            if (Math.Abs(o - x) < bestD) { bestD = Math.Abs(o - x); best = o; }
        return best;
    }

    private void ThinkGuarding(Ant a, float dt)
    {
        int x = World.X(a.Cell);
        int opening = NearestOpening(x);
        if (opening >= 0 && Threat(opening) != null) { a.Job = AntJob.Fighting; ThinkFighting(a); return; }
        bool stayIn = Season == Season.Winter || Raining || SurfaceTemp < SimConfig.ForageTemp || opening < 0;
        if (stayIn)
        {
            if (World.Y(a.Cell) == 0 || ToNursery.Reachable(a.Cell) && ToNursery.Dist[a.Cell] > 0)
            {
                var home = ToNursery.SourceCount > 0 ? ToNursery : HomeField();
                if (home != null && Follow(a, home)) return;
            }
            MillAbout(a, ToNursery);
            return;
        }
        if (World.Y(a.Cell) != 0) { Follow(a, ToSurface); return; }
        // Patrol the ground around the entrance.
        a.Timer -= dt;
        if (a.Timer > 0) return;
        a.Timer = _rng.Range(0.5f, 2.5f);
        int target = Math.Clamp(opening + _rng.Range(-(int)SimConfig.GuardRange, (int)SimConfig.GuardRange + 1), 0, World.Width - 1);
        if (target != x) Walk(a, World.Index(x + Math.Sign(target - x), 0));
    }

    private void ThinkFighting(Ant a)
    {
        int x = World.X(a.Cell);
        var s = Threat(x) ?? Threat(NearestOpening(x) < 0 ? x : NearestOpening(x));
        if (s == null) { a.Job = AntJob.Guarding; return; }
        if (World.Y(a.Cell) != 0) { Follow(a, ToSurface); return; }
        float d = s.X - (x + 0.5f);
        if (MathF.Abs(d) <= 1f) return;   // in reach: the spider update applies the bites
        Walk(a, World.Index(Math.Clamp(x + Math.Sign(d), 0, World.Width - 1), 0));
    }

    // ---------- winged queens ----------

    private void ThinkAlateWaiting(Ant a)
    {
        if (FlightUnderway) { a.Job = AntJob.ToFlight; return; }
        if (ToNursery.SourceCount > 0 && ToNursery.Reachable(a.Cell) && ToNursery.Dist[a.Cell] > 0) { Follow(a, ToNursery); return; }
        MillAbout(a, ToNursery);
    }

    private void ThinkToFlight(Ant a)
    {
        if (World.Y(a.Cell) == 0) { a.Job = AntJob.Flying; a.Flight = 0; return; }
        if (!Follow(a, ToSurface)) { a.Job = AntJob.Flying; a.Flight = 0; }
    }
}
