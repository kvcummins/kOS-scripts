// ComSat boot script
// Ken Cummins (madlemur)
//   based on work by
// Kevin Gisi
// http://youtube.com/gisikw

{
  for dependency in list(
    "mission_runner.v0.1.0.ks",
    "navigate.v0.1.0.ks",
    "maneuver.v0.1.0.ks",
    "comsat_mission.ks"
  ) if not exists(dependency) copy dependency from 0.

  run mission_runner.v0.1.0.ks.
  run navigate.v0.1.0.ks.
  run maneuver.v0.1.0.ks.
  run comsat_mission.ks.

  run_mission(comsat_mission["sequence"], comsat_mission["events"]).
}