-- Function to retreive the start date(s) and end date(s) of 
-- removal episodes for a given person.

DROP FUNCTION IF EXISTS removalEpisodes();
DROP TYPE IF EXISTS startEndDatesOfRemovalEpisodes; 
CREATE TYPE startEndDatesOfRemovalEpisodes (startDate date, endDate date);
CREATE FUNCTION removalEpisodes(person_id integer) 
   RETURNS setof startEndDatesOfRemovalEpisodes AS $$
  
  DECLARE

    inARemovalEpisode bool := 'f';
    recordFromOOHLocations RECORD;
    startDate date;
    endDate date;

    --CURSOR THAT FETCHES DATA FROM out_of_home_locations.
    
    cursForOOHLocations CURSOR FOR 
      select start_date, end_date, relocating_to_non_custodial_parent  
      from out_of_home_locations, physical_location_records
      where physical_location_records.physical_location_id = out_of_home_locations.id
      and (removal_court_ordered is not null
           or result_of_voluntary_placement_agreement is not null or family_structure is not null
           or ever_adopted is not null or supervised_independent_living is not null
           or physical_abuse is not null or sexual_abuse is not null 
           or neglect is not null or parent_alcohol_abuse is not null
           or parent_drug_abuse is not null or child_alcohol_abuse is not null
           or child_disability is not null or child_behavioral_problem is not null
           or death_of_parent is not null or incarceration_of_parent is not null
           or incarceration_of_parent is not null or caretaker_inability_to_cope is not null
           or abandonment is not null or relinquishment is not null
           or child_drug_abuse is not null or inadequate_housing is not null)
      and physical_location_records.person_id = person_id
      order by start_date;


  BEGIN
    
    FOR recordFromOOHLocations IN cursForOOHLocations LOOP

      --Get the first location for this child that was not for
      --relocating to non-custodial parent. The start_date for
      --that location is the start date of the removal episode.
      
      IF (inARemovalEpisode = 'f' AND 
           recordFromOOHLocations.relocating_to_non_custodial_parent <> 't') THEN
        startDate := recordFromOOHLocations.start_date;
        inARemovalEpisode := 't';
      END IF;
    END LOOP;
  END;
$$ LANGUAGE plpgsql;
