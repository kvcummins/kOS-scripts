{
  local lib_util is lexicon(
    "ClosestApproach", utilClosestApproach@,
    "CloseApproach", utilCloseApproach@,
    "FaceBurn", utilFaceBurn@,
    "RCSCancelVelocity", utilRCSCancelVelocity@,
    "IsShipFacing", utilIsShipFacing@
    "LongitudeTo360", utilLongitudeTo360@,
    "ReduceTo360", utilReduceTo360@
  ).

  // Determine the time of ship1's closest approach to ship2.
  function utilClosestApproach {
    parameter ship1.
    parameter ship2.

    local Tmin is time:seconds.
    local Tmax is Tmin + 2 * max(ship1:obt:period, ship2:obt:period).
    local Rbest is (ship1:position - ship2:position):mag.
    local Tbest is 0.

    until Tmax - Tmin < 5 {
      local dt2 is (Tmax - Tmin) / 2.
      local Rl is utilCloseApproach(ship1, ship2, Tmin, Tmin + dt2).
      local Rh is utilCloseApproach(ship1, ship2, Tmin + dt2, Tmax).
      if Rl < Rh {
        set Tmax to Tmin + dt2.
      } else {
        set Tmin to Tmin + dt2.
      }
    }

    return (Tmax+Tmin) / 2.
  }

  // Given that ship1 "passes" ship2 during time span, find the APPROXIMATE
  // distance of closest approach, but not precise! Use this iteratively to find
  // the true closest approach.
  function utilCloseApproach {
    parameter ship1.
    parameter ship2.
    parameter Tmin.
    parameter Tmax.

    local Rbest is (ship1:position - ship2:position):mag.
    local Tbest is 0.
    local dt is (Tmax - Tmin) / 32.

    local T is Tmin.
    until T >= Tmax {
      local X is (positionat(ship1, T)) - (positionat(ship2, T)).
      if X:mag < Rbest {
        set Rbest to X:mag.
      }
      set T to T + dt.
    }

    return Rbest.
  }

  FUNCTION utilFaceBurn {

  // This function is intended to use with shuttles and spaceplanes that have engines not in line with CoM.
  // Usage: LOCK STEERING TO utilFaceBurn(THEDIRECTIONYOUWANTTOSTEER).
  // Example: LOCK STEERING TO utilFaceBurn(PROGRADE).

    PARAMETER DIRTOSTEER. // The direction you want the ship to steer to
    LOCAL NEWDIRTOSTEER IS DIRTOSTEER. // Return value. Defaults to original direction.

    LOCAL OSS IS LEXICON(). // Used to store all persistent data
    LOCAL trueacc IS 0. // Used to store ship acceleration vector

    FUNCTION HasSensors {
      // Checks if ship have required sensors:
      // - Accelerometer (Double-C Seismic Accelerometer)
      // - Gravity Sensor (GRAVMAX Negative Gravioli Detector)
      LOCAL HasA IS False.
      LOCAL HasG IS False.
      LIST SENSORS IN SENSELIST.
      FOR S IN SENSELIST {
        IF S:TYPE = "ACC" { SET HasA to True. }
        IF S:TYPE = "GRAV" { SET HasG to True. }
      }
      IF HasA AND HasG { RETURN TRUE. }
      ELSE { RETURN FALSE. }
    }

    FUNCTION InitOSS {
      // Initialize persistent data.
      LOCAL OSS IS LEXICON().
      OSS:add("t0",time:seconds).
      OSS:add("pitch_angle",0).
      OSS:add("pitch_sum",0).
      OSS:add("yaw_angle",0).
      OSS:add("yaw_sum",0).
      OSS:add("Average_samples",0).
      OSS:add("Average_Interval",1).
      OSS:add("Average_Interval_Max",5).
      OSS:add("Ship_Name",SHIP:NAME:TOSTRING).
      OSS:add("HasSensors",HasSensors()).

      RETURN OSS.
    }

    IF EXISTS("oss.json") { // Looks for saved data
      SET OSS TO READJSON("oss.json").
      IF OSS["Ship_Name"] <> SHIP:NAME:TOSTRING {
        SET OSS TO InitOSS().
      }
    }
    ELSE {
      SET OSS TO InitOSS().
    }

    IF OSS["HasSensors"] { // Checks for sensors
      LOCK trueacc TO ship:sensors:acc - ship:sensors:grav.
    }
    ELSE { // If ship have no sensors, just returns direction without any correction
      RETURN DIRTOSTEER.
    }


    // Only account for offset thrust if there is thrust!
    if throttle > 0.1 {
        local dt to time:seconds - OSS["t0"]. // Delta Time
        if dt > OSS["Average_Interval"]  {
          // This section takes the average of the offset, reset the average counters and reset the timer.
          SET OSS["t0"] TO TIME:SECONDS.
          if OSS["Average_samples"] > 0 {
            // Pitch
            SET OSS["pitch_angle"] TO OSS["pitch_sum"] / OSS["Average_samples"].
            SET OSS["pitch_sum"] to OSS["pitch_angle"].
            // Yaw
            SET OSS["yaw_angle"] TO OSS["yaw_sum"] / OSS["Average_samples"].
            SET OSS["yaw_sum"] to OSS["yaw_angle"].
            // Sample count
            SET OSS["Average_samples"] TO 1.
            // Increases the Average interval to try to keep the adjusts more smooth.
            if OSS["Average_Interval"] < OSS["Average_Interval_Max"] {
              SET OSS["Average_Interval"] to max(OSS["Average_Interval_Max"], (OSS["Average_Interval"] + dt)) .
            }
          }
        }
        else { // Accumulate the thrust offset error to be averaged by the section above

            // Thanks to reddit.com/user/ElWanderer_KSP
            // exclude the left/right vector to leave only forwards and up/down
            LOCAL pitch_error_vec IS VXCL(FACING:STARVECTOR,trueacc).
            LOCAL pitch_error_ang IS VANG(FACING:VECTOR,pitch_error_vec).
            If VDOT(FACING:TOPVECTOR,pitch_error_vec) > 0{
              SET pitch_error_ang TO -pitch_error_ang.
            }

            // exclude the up/down vector to leave only forwards and left/right
            LOCAL yaw_error_vec IS VXCL(FACING:TOPVECTOR,trueacc).
            LOCAL yaw_error_ang IS VANG(FACING:VECTOR,yaw_error_vec).
            IF VDOT(FACING:STARVECTOR,yaw_error_vec) < 0{
              SET yaw_error_ang TO -yaw_error_ang.
            }
            //LOG "P: " + pitch_error_ang TO "0:/oss.txt".
            //LOG "Y: " + yaw_error_ang TO "0:/oss.txt".
            set OSS["pitch_sum"] to OSS["pitch_sum"] + pitch_error_ang.
            set OSS["yaw_sum"] to OSS["yaw_sum"] + yaw_error_ang.
            SET OSS["Average_samples"] TO OSS["Average_samples"] + 1.
        }
        // Set the return value to original direction combined with the thrust offset
        //SET NEWDIRTOSTEER TO r(0-OSS["pitch_angle"],OSS["yaw_angle"],0) * DIRTOSTEER.
        SET NEWDIRTOSTEER TO DIRTOSTEER.
        IF ABS(OSS["pitch_angle"]) > 1 { // Don't bother correcting small errors
          SET NEWDIRTOSTEER TO ANGLEAXIS(-OSS["pitch_angle"],SHIP:FACING:STARVECTOR) * NEWDIRTOSTEER.
        }
        IF ABS(OSS["yaw_angle"]) > 1 { // Don't bother correcting small errors
          SET NEWDIRTOSTEER TO ANGLEAXIS(OSS["yaw_angle"],SHIP:FACING:UPVECTOR) * NEWDIRTOSTEER.
        }
    }
    // This function is pretty processor intensive, make sure it don't execute too much often.
    WAIT 0.2.
    // Saves the persistent values to a file.
    WRITEJSON(OSS,"oss.json").
    RETURN NEWDIRTOSTEER.
  }


  FUNCTION utilRCSCancelVelocity {
    // MUST Be a delegate to a vector
    // Example:
    //
    // LOCK myVec to myNode:DeltaV.
    // utilRCSCancelVelocity(myVec@).
    parameter CancelVec.
    parameter residualSpeed is 0.01. // Admissible residual speed.
    parameter MaximumTime is 15. // Maximum time to achieve results.

    local lock tgtVel to -CancelVec().

    //Save ship's systems status
    local rstatus is rcs.
    local sstatus is sas.

    // Prevents ship to rotate
    sas off.
    lock steering to ship:facing.
    uiDebug("Fine tune with RCS").
    // Cancel the speed.
    rcs on.
    local t0 is time.
    until tgtVel:mag < residualSpeed or (time - t0):seconds > MaximumTime {
      local sense is ship:facing.
      local dirV is V(
        vdot(tgtVel, sense:starvector),
        vdot(tgtVel, sense:upvector),
        vdot(tgtVel, sense:vector)
      ).
      set ship:control:translation to dirV:normalized.
      wait 0.
    }

    //Return ship controls to previus condition
    set ship:control:translation to v(0,0,0).
    set ship:control:neutralize to true.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
    UNLOCK STEERING.
    UNLOCK THROTTLE.
    set rcs to rstatus.
    set sas to sstatus.
  }

  // Returns true if:
  // Ship is facing the FaceVec whiting a tolerance of maxDeviationDegrees and
  // with a Angular velocity less than maxAngularVelocity.
  function utilIsShipFacing {
    parameter FaceVec.
    parameter maxDeviationDegrees is 8.
    parameter maxAngularVelocity is 0.01.

    return vdot(FaceVec, ship:facing:forevector) >= cos(maxDeviationDegrees) and
           ship:angularvel:mag < maxAngularVelocity.
  }

  FUNCTION utilLongitudeTo360 {
      //Converts longitudes from -180 to +180 into a 0-360 degrees.
      //From youtube.com/cheerskevin
      PARAMETER lng.
      RETURN MOD(lng + 360, 360).
  }

  function utilReduceTo360 {
    //Converts angles that are more tha 360 to 0-360
    parameter ang.
    return ang - 360 * floor(ang/360).
  }

  export(lib_util).
}