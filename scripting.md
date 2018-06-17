(*boot.ks*)
+ *lexicon* `import`(*filename*)
+ *void* `export`(*lexicon*)
+ *void* `phud`(*string*, *delay*=`3`, *position*=`2`, *size*=`40`, *color*=`YELLOW`, *echo_console*=`FALSE`)
+ *void* `pout`(*string*)
+ *void* `plog`(*string*)
+ *bool* `slog`(*filename*)
+ *string* `padRep`(*width*, *char*, *string*)

**__** (*boot.ks*)
+ *void* `stage`()
+ *degrees* `mAngle`(*degrees*)
+ *void* `killWarp`()
+ *bool* `warpUntil`(*seconds_UT*, *stop_delegate*=`{ RETURN FALSE. }`)
+ *bool* `doWarp`(*seconds*)

**diskio** (*diskio.ks*)
+ *bool* `init`()
+ *array* `listVolumes`()
+ *filepath* `findfile`(*filename*)
+ *filepath* `findspace`(*filename*, *bytes*)
+ *filepath* `loadfile`(*filename*, *delete_original*=`FALSE`)
+ *mixed* `runfile`(*filepath*)
+ *bool* `delfile`(*filepath*)
+ *bool* `store`(*string*, *filename*, *bytes*=`150`)
+ *bool* `append`(*string*, *filename*)

**volmgt** (*volmgt.ks*)
+ *bool* `init`()
+ *array* `listVolumes`()
+ *filepath* `findfile`(*filename*)
+ *filepath* `findspace`(*filename*, *bytes*)

**time** (*time.ks*)
+ *void* `setTime`(*timename*, *time*=`TIME:SECONDS`)
+ *seconds* `diffTime`(*timename*)
+ *seconds* `stageTime`()

**text** (*text.ks*)
+ *string* `formatTS`(*seconds_UT*, *seconds_from*=`TIME:SECONDS`)
+ *string* `formatMET`()

**mission** (*mission.ks*)
+ *bool* `init`()
+ *bool* `loadMission`(*filepath*, *string*=`padRep(0,'_',SHIP:NAME)`)
+ *void* `runMission`(*string*=`padRep(0,'_',SHIP:NAME)`)
+ *bool* `next`()
+ *bool* `addEvent`(*string*, *delegate*)
+ *bool* `hasEvent`(*string*)
+ *bool* `pauseEvent`(*string*)
+ *bool* `startEvent`(*string*)
+ *bool* `delEvent`(*string*)
+ *bool* `switchTo`(*string*)
+ *string* `currRunmode`()
+ *bool* `terminate`()
+ *bool* `addData`(*string*, *mixed*, *bool*=`FALSE`)
+ *bool* `delData`(*string*)
+ *mixed* `getData`(*string*)
+ *bool* `hasData`(*string*, *bool*=`TRUE`)

**launcher** (*launcher.ks*)
+ *bool* `init`()
+ *bool* `setLaunchParameters`(
    *pitch_altitude*=`250`,
    *curve_altitude*=`BODY:ATM:HEIGHT * 0.9`,
    *curve_delegate*=`{ IF ALTITUDE < pitch_altitude RETURN 90. RETURN MIN(90,MAX(0, MAX(90 * (1 - SQRT(ALTITUDE/curve_altitude)),45-VERTICALSPEED))). }`
  )
+ *lexicon* `calcLaunchDetails`(*altitude*, *inclination*=`0`, *LAN*=`''`)
+ *degrees* `getBearing`()
+ *degrees* `getPitch`()
+ *percentage* `getThrottle`()

**events** (*events.ks*)
+ *bool* `init`()
+ *void* `checkForStaging`()
+ *void* `jettisonFairings`()
+ *void* `enableComms`()
+ *void* `transmitScience`()