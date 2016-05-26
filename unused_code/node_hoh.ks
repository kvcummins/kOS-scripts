// Delta vee math stolen from http://en.wikipedia.org/wiki/Hohmann_transfer_orbit#Calculation
// Phase angle math stolen from https://docs.google.com/document/d/1IX6ykVb0xifBrB4BRFDpqPO6kjYiLvOcEo3zwmZL0sQ/edit

run lib_ui.

// TODO deal properly with approach distance...
// this is VERY rough and might not work for all mu/radii!
function approachDistance {
  local ratio is target:mass / ship:mass.

  if ratio > 1000 {
    return 0.
  } else {
    return 0.
  }
}

function synodicPeriod {
  parameter o1, o2.

  if o1:period > o2:period {
    local o is o2.
    set o2 to o1.
    set o1 to o.
  }

  return 1 / ( (1 / o1:period) - (1 / o2:period) ).
}

function hohmann {
  local r1 is (ship:obt:semimajoraxis + ship:obt:semiminoraxis) / 2.
  local r2 is (target:obt:semimajoraxis + target:obt:semiminoraxis) / 2.
  local approach is 0.

  if r2 > r1 {
    set approach to approachDistance().
  } else {
    set approach to -approachDistance().
  }

  // dv is not a vector in cartesian space, but rather in "maneuver space"
  // (z = prograde/retrograde dv)
  local dv is V(0, 0, sqrt(body:mu / r1) * (sqrt( (2*(r2-approach)) / (r1+r2-approach) ) - 1)).
  local pt is 0.5 * ((r1+r2) / (2*r2))^1.5.
  local ft is pt - floor(pt).

  // angular distance that target will travel during transfer
  local theta is 360 * ft.
  // necessary phase angle for vessel burn
  local phi is 180 - theta.

  local T is time:seconds.
  local Tmax is T + 1.5 * synodicPeriod(ship:obt, target:obt).
  local dt is (Tmax - T) / 20.

  local result is lexicon().

  until false {
    local ps is positionat(ship, T) - body:position.
    local pt is positionat(target, T) - body:position.
    local vs is velocityat(ship, T):orbit.
    local vt is velocityat(target, T):orbit.

    // angular velocity of vessel
    local omega is (vs:mag / ps:mag)  * (180/constant():pi).
    // angular velocity of the target
    local omega2 is (vt:mag / pt:mag)  * (180/constant():pi).

    // unsigned magnitude of the phase angle between ship and target
    local phiT is vang(ps, pt).
    // if r2 > r1, then norm:y is negative when ship is "behind" the target
    local norm is vcrs(ps, pt).
    // < 0 if ship is on opposite side of planet
    local dot is vdot(vs, vt).

    local eta is 0.

    if r2 > r1 {
      set eta to (phiT - phi) / (omega - omega2).
    } else {
      set eta to (phiT + phi) / (omega2 - omega).
    }

    // TODO make sure this heuristic works for all cases:
    //   - rendezvous up (untested)
    //   - transfer down (untested)
    if T > Tmax {
      result:add("time", 0).
      result:add("dv", dv).
      return result.
    } else if r2 > r1 and norm:y > 0 {
      uiDebugNode(T, dv, "ship is ahead of target").
      set T to T + dt.
    } else if r2 < r1 and norm:y < 0 {
      uiDebugNode(T, dv, "ship is behind target").
      set T to T + dt.
    } else if (r2 > r1 and dot > 0) or (r2 < r1 and dot < 0) {
      uiDebugNode(T, dv, "ship is opposite target").
      set T to T + dt.
    } else if eta < -1 {
      uiDebugNode(T, dv, "eta is in the past").
      set T to T + dt.
    } else if abs(eta) > 1 {
      uiDebugNode(T, dv, "eta is too far").
      set T to T + eta / 2.
    } else {
      uiDebugNode(T, dv, "found window! eta=" + round(eta) + " phiT=" + round(phiT, 1) + " phi=" + round(phi, 1)).
      result:add("time", T + eta).
      result:add("dv", dv).
      return result.
    }
  }
}

if body <> target:body {
  uiWarning("Node", "Incompatible orbits").
}
if ship:obt:eccentricity > 0.1 {
  uiWarning("Node", "Eccentric ship e=" + round(ship:obt:eccentricity, 1)).
}
if target:obt:eccentricity > 0.1 {
  uiWarning("Node", "Eccentric target e=" +  + round(target:obt:eccentricity, 1)).
}
if abs(obt:inclination - target:obt:inclination) > 0.2 {
  uiWarning("Node", "Bad alignment ri=" +  + round(ri, 1)).
}

local T is hohmann().

if T:haskey("time") {
  add node(T["time"], T["dv"]:x, T["dv"]:y, T["dv"]:z).
} else {
  uiError("Node", "NO TRANSFER WINDOW").
}
