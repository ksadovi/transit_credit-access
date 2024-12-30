# The output object routing includes five columns: tract number, the number of minutes it takes to walk to the 
# nearest train station, the number of miles on foot to the nearest train station, and the closest train station by 
# miles and by distance (they should be the same unless there's a very marginal case)

map_station_distances = function(centroids, length = "all"){
  centroids = centroids
  stations = fread("3_output/cleaned_data/station_polygons.csv")
  routing = data.frame()
  if(length == "all"){
    end = nrow(centroids)
  } else{
    end = length
  }
  timing = system.time(for(i in c(1:end)){
    stats = data.frame()
    for(j in 1:length(stations$station)){
      tryCatch(
        {route = osrmRoute(
          src = st_coordinates(centroids$geometry[i]), 
          dst = stations[j, 1:2], 
          osrm.profile = "foot"
        )}, error = function(msg){
          return(NA)
        }
      )
      info = cbind(route$duration, route$distance*0.621371, stations$station[j])
      stats = rbind(stats, info) 
      
    }
    colnames(stats) = c("minutes", "miles", "station_name")
    stats$minutes = as.numeric(stats$minutes)
    stats$miles = as.numeric(stats$miles)
    min_dur = min(stats$minutes)
    min_dist = min(stats$miles)
    closest_dur = stats$station_name[which(stats$minutes == min_dur)]
    closest_dist = stats$station_name[which(stats$miles == min_dist)]
    tract = dmv_tract_centroids$GEOID[i]
    info2 = cbind(tract, min_dur, min_dist, closest_dur, closest_dist)
    routing = rbind(routing, info2)
  })
  return(list(routing, timing))
}

#This takes a really long time to run because it's super inefficient -- four tracts takes 50 seconds. 
# Need to come up with a better way to do this, especially once I want to start getting more granular 
# or use individuals rather than tracts. 
