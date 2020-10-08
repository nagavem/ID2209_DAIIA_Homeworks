	
	model BDI
	
	global {
		
		//all predicates
	string party_at_location <- "party_at_location";
	string chill_at_location<- "chill_at_location";
	string food_at_location<-"food_at_location";
	string gamble_at_location<-"gamble_at_location";
	string empty_concert_location <- "empty_concert_location";
	
	predicate party_desire <- new_predicate("party_desire");
	predicate chill_desire <- new_predicate("chill_desire");
	predicate gamble_desire <- new_predicate("gamble_desire");
	predicate wander_desire <- new_predicate("wander_desire");
	predicate food_desire <- new_predicate("food_desire");
	
	predicate party_location <- new_predicate(party_at_location);
	predicate chill_location <- new_predicate(chill_at_location);
	predicate find_party_loc <- new_predicate("find_party_loc");
	
	predicate set_party_location_as_target <- new_predicate("set_party_location_as_target");
	predicate set_chill_location_as_target<- new_predicate("set_chill_location_as_target");
	predicate set_gamble_location_as_target<- new_predicate("set_gamble_location_as_target");
	predicate set_food_location_as_target<- new_predicate("set_food_location_as_target");
	
	int number_of_people <- 50;
	
	int total_conversations <- 0;
	int total_denies <- 0;
	int partied <- 0;
	int chilled <- 0;
	int ate <- 0;
	int gambled <- 0;
	map<string, int> happiness_level_map;
	list<int>all_happiness_values;
	map<string, int> drunk_level_map;
	map<string, string> agent_type_map;
	int partyEnthusiast_number<-0;
	int chillPerson_number<-0;
	int gambler_number<-0;
	int normal_number<-0;
	int weird_number<-0;
	int gambling_people<-0;
	int gambling_winners<-0;
	
	
	
	
	init{
		create visitor number: number_of_people;
		
		create party_place number: 1
				{
					
				}
				
		create drinks_chill_place number: 1
				{
					
				}
				
		create food_court number: 1
				{
					
				}
				
		create gambling_area number: 1
				{
					
					}
			create concert_stage number:1
			{
				
			} 
		}
	}
	
	species visitor skills:[moving, fipa] control: simple_bdi{
		init{
			 gambling_people<-0;
			gambling_winners<-0;
			
		}
		
		string get_agent_type {
			switch rnd(0, 99) {
				match_between [0, 40] {return 'normal';}	
			match_between [41, 58] {return 'partyEnthusiast';}	
			match_between [59, 76] {return 'chillPerson';}	
			match_between [77, 94] {return 'gambler';}	
			match_between [95, 99] {return 'weird';}	
			default {return 'weird';}
		}
	}
	
	
	string agent_type <- get_agent_type();
	list<visitor> allVisitors;
	list<string> allVisitorsNames;
	init{
	allVisitors<-list(visitor);
	allVisitorsNames <- allVisitors collect each.name;
	loop i from: 0 to: length(allVisitorsNames)-1
	{
		add allVisitorsNames[i] :: 0 to: happiness_level_map;
		add allVisitorsNames[i] :: 0 to: drunk_level_map;
		add allVisitorsNames[i] :: "" to: agent_type_map;
		
	}
	
	}
	
	int wealthy <- rnd(0, 9);
	bool talkative <- flip(0.5);
	int generous <- rnd(0, 9);
	
	int food_level <- rnd(150, 200) min: 0 update: food_level - 1;
	
	string status <- 'wandering';
	
	string present_desire <- nil;
	int desire_completion <- 0;
	
	point target <- nil;
	point wander_point <- self.location;
	
	
	action update_desire{
		if present_desire= 'party'{
			do add_desire(party_desire);
		} 
		
		else if present_desire= 'chill'{
			do add_desire(chill_desire);
			drunk_level_map[name]<- drunk_level_map[name]+1;
			
		}
		
		else if present_desire= 'gamble'{
			
			gambling_people<-gambling_people+1;
			do add_desire(gamble_desire);
		}
		
		else if present_desire='wander'{
			
			do add_desire(wander_desire);
		}
		else if present_desire='food'{
			
			do add_desire(food_desire);
			drunk_level_map[name]<- drunk_level_map[name]-1;
			if(drunk_level_map[name]<0){
				drunk_level_map[name]<-0;
			}
		}
		}
		
		
	// belief for party..........................................................................
	perceive target: party_place{
		
		focus id: party_at_location var: location;
			
	}
	
	//end------------------------------------------------------------------------------------
	
	// belief for chilling..........................................................................
	perceive target: drinks_chill_place{
		
		focus id: chill_at_location var: location;
		
		
	}
	//end------------------------------------------------------------------------------------
	
	// belief for gambling..........................................................................
	perceive target: gambling_area{
		
		focus id: gamble_at_location var: location;
		
	}
	//end------------------------------------------------------------------------------------
	
	// belief for food..........................................................................
	perceive target: food_court{
		
		focus id: food_at_location var: location;
		
	}
	//end------------------------------------------------------------------------------------
	
	
	
	//plans for party------------------------------------------------------------------------------
	plan party intention: party_desire{
		if (target= nil){
			do add_subintention(get_current_intention(),set_party_location_as_target, true);
	        do current_intention_on_hold();
		}
	    else{
	    	do goto target: target ;
	    
	    	if (target = location)  {
	    		
	    		desire_completion <- desire_completion + 1;
				do wander;
				
				
				
			if (desire_completion >= 20) {
				
				target<-nil;
				desire_completion <- 0;
				present_desire <- nil;
				do remove_intention(party_desire, true);
				
				
				
				}
	        	}
	        
	        }
	   }
	   
	   plan set_party_location_as_target intention:set_party_location_as_target instantaneous:true
	   	{
	   		party_place partyPlace;
	   		list<point> possible_party_locations <- get_beliefs_with_name(party_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		
		 target <- (possible_party_locations with_min_of (each distance_to self)).location;
		 
		 do remove_intention(set_party_location_as_target, true);
	 }
	 
	//plans for chill------------------------------------------------------------------------------
	plan chill intention: chill_desire{
		if (target= nil){
			do add_subintention(get_current_intention(),set_chill_location_as_target, true);
	        do current_intention_on_hold();
		}
	    else{
	    	do goto target: target ;
	    
	    	if (target = location)  {
	    		
	    		desire_completion <- desire_completion + 1;
				do wander;
				
				
				
			if (desire_completion >= 20) {
				
				target<-nil;
				desire_completion <- 0;
				present_desire <- nil;
				do remove_intention(chill_desire, true);
				
				
			
				}
	        	}
	        
	        }
	   }
	   
	   plan set_chill_location_as_target intention:set_chill_location_as_target instantaneous:true
	   	{
	   		
		list<point> possible_chill_locations <- get_beliefs_with_name(chill_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		
		 target <- (possible_chill_locations with_min_of (each distance_to self)).location;
		
		 do remove_intention(set_chill_location_as_target, true);
	 }
	
	
	//plans for gamble------------------------------------------------------------------------------
	plan gamble intention: gamble_desire{
		bool gambling_winner;
		point concert_stage_loc;
		
		if (target= nil){
			do add_subintention(get_current_intention(),set_gamble_location_as_target, true);
	        do current_intention_on_hold();
		}
	    else{
	    	do goto target: target ;
	    
	    	if (target = location)  {
	    		
	    		desire_completion <- desire_completion + 1;
				do wander;
				
				
				
			if (desire_completion >= 20) {
				//BDI implementation for the creative part
				//the code checks if the person is winner, if yes it asks concert_stage for its location and adds a belief
				ask gambling_area {
					gambling_winner <- winner;
				}
				if(gambling_winner=true){
					
					gambling_winners<-gambling_winners+1;
					
					ask concert_stage{
						concert_stage_loc<-location;
					}
					do add_belief(new_predicate(empty_concert_location, ["location_value"::concert_stage_loc]));
				}
				target<-nil;
				desire_completion <- 0;
				
				present_desire <- nil;
				do remove_intention(gamble_desire, true);
				
			
				}
	        	}
	        
	        }
	   }
	   
	   plan set_gamble_location_as_target intention:set_gamble_location_as_target instantaneous:true
	   	{
	   		
		list<point> possible_gamble_locations <- get_beliefs_with_name(gamble_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		list<point> possible_concert_stage <- get_beliefs_with_name(empty_concert_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		// code for the creative part 
		// target location for the visitor is set to concert_stage
		
		if(empty(possible_concert_stage)){
		 target <- (possible_gamble_locations with_min_of (each distance_to self)).location;
		 }
		 else{
		 	write name+ "gambling winner going to concert stage";
		 	target<-(possible_concert_stage with_min_of (each distance_to self)).location;
		 }
		
		 do remove_intention(set_gamble_location_as_target, true);
	 }
	 
	 //end---------------------------------------------------------------------------------
	//plan wander desire----------------------------------------------------
	plan wander intention: wander_desire {
		
		float x_wander_min <- (self.location.x - 10) < 0 ? 0 : self.location.x - 10;
		float x_wander_max <- (self.location.x + 10) > 100 ? 100 : self.location.x + 10;
		float y_wander_min <- (self.location.y - 10) < 0 ? 0 : self.location.y - 10;
		float y_wander_max <- (self.location.y + 10) > 100 ? 100 : self.location.y + 10;
		
		
		do goto target: point(rnd(x_wander_min, x_wander_max), rnd(y_wander_min, y_wander_max));
		desire_completion <- desire_completion + 1;
		if (desire_completion >= 35) {
				
				target<-nil;
				desire_completion <- 0;
				present_desire <- nil;
				do remove_intention(wander_desire, true);
		
			}
		
		
	}
	
	//end---------------------------------------------------------------------------------
	
	//plans for food------------------------------------------------------------------------------
	plan food intention: food_desire{
		if (target= nil){
			do add_subintention(get_current_intention(),set_food_location_as_target, true);
	        do current_intention_on_hold();
		}
	    else{
	    	do goto target: target ;
	    
	    	if (target = location)  {
	    		
	    		desire_completion <- desire_completion + 1;
				do wander;
				
			
				
			if (desire_completion >= 20) {
				
				target<-nil;
				desire_completion <- 0;
				present_desire <- nil;
				do remove_intention(food_desire, true);
				
				
				
				}
	        	}
	        
	        }
	   }
	   
	   plan set_food_location_as_target intention:set_food_location_as_target instantaneous:true
	   	{
	   		
		list<point> possible_food_locations <- get_beliefs_with_name(food_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	
		 target <- (possible_food_locations with_min_of (each distance_to self)).location;
		
		 do remove_intention(set_food_location_as_target, true);
	 }
	 
	 //end---------------------------------------------------------------------------------
	
	
	reflex get_a_present_desire when: present_desire = nil {
		int roll <- rnd(0, 99);
		
		switch agent_type {
			match 'normal' {
				switch roll {
					match_between [0, 24] {present_desire <- 'party';}		
					match_between [25, 34] {present_desire <- 'chill';}		
					match_between [35, 39] {present_desire <- 'gamble';}		
					match_between [40, 70] {present_desire <- 'food';}		
					default {present_desire <- 'wander';}						
				}
			}
			match 'partyEnthusiast' {
				switch roll {
					match_between [0, 39] {present_desire <- 'party';}		
					match_between [40, 54] {present_desire <- 'chill';}		
					match_between [35, 39] {present_desire <- 'gamble';}		
					match_between [55, 74] {present_desire <- 'food';}		
					default {present_desire <- 'wander';}						
				}
			}
			match 'chillPerson' {
				switch roll {
					match_between [0, 14] {present_desire <- 'party';}		
					match_between [15, 49] {present_desire <- 'chill';}		
					match_between [50, 59] {present_desire <- 'gamble';}		
					match_between [60, 74] {present_desire <- 'food';}		
					default {present_desire <- 'wander';}						
				}
			}
			match 'gambler' {
				switch roll {
					match_between [0, 9] {present_desire <- 'party';}		
					match_between [10, 19] {present_desire <- 'chill';}		
					match_between [20, 59] {present_desire <- 'gamble';}		
					match_between [60, 74] {present_desire <- 'food';}		
					default {present_desire <- 'wander';}						
				}
			}
			match 'weird' {
				switch roll {
					match_between [0, 4] {present_desire <- 'party';}		
					match_between [5, 9] {present_desire <- 'chill';}		
					match_between [10, 14] {present_desire <- 'gamble';}		
					match_between [15, 19] {present_desire <- 'food';}		
					default {present_desire <- 'wander';}						
				}
			}
			default {}
		}
		do update_desire;
	}
	
	reflex agent_type_value{
		if(agent_type='normal'){
			normal_number<-normal_number+1;
			
		}
		if(agent_type='partyEnthusiast'){
			partyEnthusiast_number<-partyEnthusiast_number+1;
		}
		if(agent_type='chillPerson'){
			chillPerson_number<-chillPerson_number+1;
		}
		if(agent_type='gambler'){
			gambler_number<-gambler_number+1;
		}
		if(agent_type='weird'){
			weird_number<-weird_number+1;
			
		}
		
	
		
	}
	
	
	reflex answer_visitor when: !empty(informs) {
		point party_place_loc;
		point chill_place_loc;
		point gamble_place_loc;
		point food_place_loc;
		int happinessLevel;
		
		
		
		ask party_place{
			party_place_loc<-location;
			
		}
		ask drinks_chill_place{
			chill_place_loc<-location;
			
		}
		ask gambling_area{
			gamble_place_loc<-location;
			
		}
		ask food_court{
			food_place_loc<-location;
			
		}
		
		switch agent_type {
			match 'normal' {
				// normal person
				message one_inform <- informs[length(informs) - 1];
				
					if (self.location distance_to party_place_loc <=5){
					
						if (int(one_inform.contents[2])>=5 and one_inform.contents[1] != 'weird') {
							write name+"is a"+agent_type+"partying with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1];
							do agree message: one_inform contents: ['Yes lets party'];
							total_conversations <- total_conversations + 1;
							if(one_inform.contents[1]='normal'){
								happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
								
								}
							else{
								happinessLevel<- 6;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
								}	
							
						} else {
							write name+"is a"+agent_type+"doesnt want to party with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1];
							do cancel message: one_inform contents: ['No I am not interested'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
						
					}
					
					else if (self.location distance_to chill_place_loc <=5){
					
						if (int(one_inform.contents[4])<=5 and one_inform.contents[1] != 'weirdo') {
							write name+"is a"+agent_type+"chilling with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1];
							do agree message: one_inform contents: ['Yes lets chill'];
							total_conversations <- total_conversations + 1;
							if(one_inform.contents[1]='normal'){
								happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
								
								}
							else{
								happinessLevel<- 6;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
								}	
							
						} else {
							write name+"is a"+agent_type+"doesnt want to chill with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1];
							
							do cancel message: one_inform contents: ['No not interested'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
					}
					
					else if (self.location distance_to food_place_loc <=5){
					
						if (one_inform.contents[1] = agent_type) {
							write name+"is a"+agent_type+"having food with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1];
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
							happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
							happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
						} else {
							write name+"is a"+agent_type+"doesnt want to have food with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1];
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
					}
					else if (self.location distance_to gamble_place_loc <=5){
					
						if (int(one_inform.contents[3])>= 5 and wealthy >= 5) {
							write name+"is a"+agent_type+"gambling with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1];
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
							happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
							happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
						} else {
							write name+"is a"+agent_type+"doesnt want to gamble with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1];
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
					}
				
			}
	//normal person end-------------------------------------------------------------------------------------------
	
			match 'partyEnthusiast' {
				// party person
				message one_inform <- informs[length(informs) - 1];
				if (self.location distance_to party_place_loc <=5){
				
						if ((int(one_inform.contents[2])>=5 or int(one_inform.contents[4])>=5)) {
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							if(one_inform.contents[1]='partyEnthusiast'){
								happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
								
							}
							else{
								happinessLevel<- 5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
								
							}
						}
						
						else {
							write name+"is a"+agent_type+"doesnt want to party with "+ one_inform.contents[1]+"whose is less generous and less talkative" ;
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
						
					}
					//chill-----------------------------------------------------------------------------------------
					else if (self.location distance_to chill_place_loc <=5){
					
						if (int(one_inform.contents[2])>=5 and (one_inform.contents[1]!='gambler' and one_inform.contents[1]!='weird')){ 
						
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							if(one_inform.contents[1]='chillPerson'){
								happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
								
							}
							else{
								happinessLevel<- 5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
								
							}
							
						} else {
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
					}
					//food----------------------------------------------------------------------------------
					else if (self.location distance_to food_place_loc <=5){
					
						if (one_inform.contents[1] = agent_type) {
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
	
							
						} else {
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
					}
					//gamble--------------------------------------------------------------------------------------------------------
					else if (self.location distance_to gamble_place_loc <=5){
					
						if (int(one_inform.contents[3]) >= 5 and wealthy >= 5) {
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
	
						
						} else {
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
					}
				
			}
	//end-----------------------------------------------------------------------------------------------------------------------			
			match 'chillPerson' {
				// chill person
				message one_inform <- informs[length(informs) - 1];
				if (self.location distance_to party_place_loc <=5){
				
						do cancel message: one_inform contents: ['No'];
						total_denies <- total_denies + 1;
						
						do end_conversation message: one_inform contents: ['Action'];
						
					}
					else if (self.location distance_to chill_place_loc <=5){
				
						do agree message: one_inform contents: ['Yes'];
						total_conversations <- total_conversations + 1;
						happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
	
						
						do end_conversation message: one_inform contents: ['Action'];
					}
					else if (self.location distance_to food_place_loc <=5){
					
						if (one_inform.contents[1] = agent_type) {
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
	
							
						} else {
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
					}
					else if (self.location distance_to gamble_place_loc <=5){
					
						if (int(one_inform.contents[3]) >= 3 and wealthy >= 6) {
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						} else {
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
						
						}
						do end_conversation message: one_inform contents: ['Action'];
					}
				
			}
			match 'gambler' {
				// gambler person
				message one_inform <- informs[length(informs) - 1];
				if (self.location distance_to party_place_loc <=5){
				
						if (int(one_inform.contents[2])>=5 and one_inform.contents[1] != 'weirdo') {
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						} else {
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
						
					}
					else if (self.location distance_to chill_place_loc <=5){
					
						if ((int(one_inform.contents[4]) <= 5) and one_inform.contents[1] != 'weirdo' and wealthy = 0) {
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						} else {
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
					}
					else if (self.location distance_to food_place_loc <=5){
					
						if (one_inform.contents[1] = agent_type) {
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						} else {
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
					}
					else if (self.location distance_to gamble_place_loc <=5){
				
						if (int(one_inform.contents[3]) >= 5 and wealthy >= 5) {
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
							
						} else {
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
					}
				
			}
			
			match 'weird' {
				// weird person
				message one_inform <- informs[length(informs) - 1];
				if (self.location distance_to party_place_loc <=5){
				
						do agree message: one_inform contents: ['Yes'];
						total_conversations <- total_conversations + 1;
						happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
						
						
						do end_conversation message: one_inform contents: ['Action'];
						
					}
					else if (self.location distance_to chill_place_loc <=5){
					
						do agree message: one_inform contents: ['Yes'];
						total_conversations <- total_conversations + 1;
						happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
						
						
						do end_conversation message: one_inform contents: ['Action'];
					}
					else if (self.location distance_to food_place_loc <=5){
					
						if (one_inform.contents[1] = agent_type) {
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						} else {
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
					}
					else if (self.location distance_to gamble_place_loc <=5){
				
						if (int(one_inform.contents[3]) >= 5) {
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						} else {
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
					}
				
			}
		}
		write "####################happiness_Level_map"+happiness_level_map;
		
		
	}
	
	visitor asked_last_time <- nil;
	reflex ask_visitor when: food_level != 0 and !(empty(visitor at_distance 5)) {
		switch agent_type {
			match 'normal' {
				bool should_ask <- flip(0.3);
				if (should_ask) {
					list<visitor> nearby_visitors <- visitor at_distance 5;
					visitor selected_visitor <- nearby_visitors[rnd(0, length(nearby_visitors) - 1)];
					if (asked_last_time != selected_visitor) {
						do start_conversation to: [selected_visitor] protocol: 'fipa-contract-net' performative: 'inform' contents: [name, agent_type, generous, wealthy, talkative];	
					}
					asked_last_time <- selected_visitor;
				} else {
					asked_last_time <- visitor at_distance 5 at 0;
				}
			}
			match 'partyEnthisiast' {
				bool should_ask <- flip(0.5);
				if (should_ask) {
					list<visitor> nearby_visitors <- visitor at_distance 5;
					visitor selected_visitor <- nearby_visitors[rnd(0, length(nearby_visitors) - 1)];
					if (asked_last_time != selected_visitor) {
						do start_conversation to: [selected_visitor] protocol: 'fipa-contract-net' performative: 'inform' contents: [name, agent_type, generous, wealthy, talkative];
					}
					asked_last_time <- selected_visitor;	
				} else {
					asked_last_time <- visitor at_distance 5 at 0;
				}
			}
			match 'chillPerson' {
				bool should_ask <- flip(0.15);
				if (should_ask) {
					list<visitor> nearby_visitors <- visitor at_distance 5;
					visitor selected_visitor <- nearby_visitors[rnd(0, length(nearby_visitors) - 1)];
					if (asked_last_time != selected_visitor) {
						do start_conversation to: [selected_visitor] protocol: 'fipa-contract-net' performative: 'inform' contents: [name, agent_type, generous, wealthy, talkative];	
					}
					asked_last_time <- selected_visitor;	
				} else {
					asked_last_time <- visitor at_distance 5 at 0;
				}
			}
			match 'gambler' {
				bool should_ask <- flip(0.1);
				if (should_ask) {
					list<visitor> nearby_visitors <- visitor at_distance 5;
					visitor selected_visitor <- nearby_visitors[rnd(0, length(nearby_visitors) - 1)];
					if (asked_last_time != selected_visitor) {
						do start_conversation to: [selected_visitor] protocol: 'fipa-contract-net' performative: 'inform' contents: [name, agent_type, generous, wealthy, talkative];	
					}
					asked_last_time <- selected_visitor;	
				} else {
					asked_last_time <- visitor at_distance 5 at 0;
				}
			}
			match 'weird' {
				bool should_ask <- flip(0.9);
				if (should_ask) {
					list<visitor> nearby_visitors <- visitor at_distance 5;
					visitor selected_visitor <- nearby_visitors[rnd(0, length(nearby_visitors) - 1)];
					if (asked_last_time != selected_visitor) {
						do start_conversation to: [selected_visitor] protocol: 'fipa-contract-net' performative: 'inform' contents: [name, agent_type, generous, wealthy, talkative];	
					}
					asked_last_time <- selected_visitor;	
				}
			}
		}
		
	}
	
	
	
	//	Rendering the visitor:
	
	rgb get_color {
		if (self.agent_type = 'partyEnthusiast') {
			return #white;
		} else if (self.agent_type = 'chillPerson') {
			return #darkgray;
		} else if (self.agent_type = 'normal') {
			return #green;
		} else if (self.agent_type = 'gambler') {
			return #black;
		} else {
			// for 'weirdo'
			return #red;
		}
	}
	
	aspect base {
		draw sphere(2) color: get_color() border: get_color() = #white ? #black : #white;
	
		}
	}
	
	
	
	species party_place{
		aspect base{
			draw circle(15) color:#red;
		}
	}
	
	species drinks_chill_place{	
		aspect base{
			
			draw circle(15) color:#green;
		}	
	}
	
	species food_court{
		aspect base{
			draw circle(15) color:#yellow;	
		}
	}
	
	species gambling_area{
		bool winner<- flip(0.9);
		aspect base{
			draw circle(15) color:#blue;		
		}
	}
	
	species concert_stage skills:[fipa]
	{
		rgb mycolor<- rnd_color(255);
		
		aspect default
		{
			draw cube (10) at: location color: #chocolate;
			draw sphere(1) at: location + point([0.0, 0.0, 10.0]) color: mycolor;
			draw sphere(1) at: location + point([2.0, 2.0, 10.0]) color: mycolor;
			draw sphere(1) at: location + point([4.0, 4.0, 10.0]) color: mycolor;
			draw sphere(1) at: location + point([-2.0, -2.0, 10.0]) color: mycolor;
			draw sphere(1) at: location + point([-4.0, -4.0, 10.0]) color: mycolor;
			//draw sphere(1) at: location + point([10.0, 10.0, 10.0]) color: mycolor;
			
		}
		 reflex changecolor{
		 	mycolor<-flip(0.5)? rnd_color(255) : rnd_color(255);
		 } 
		
	}
	
	experiment my_experiment type: gui {
	//	parameter "Number of visitors" var: number_of_people;
	output {
		display map_3D type: opengl{
			//grid festival_map lines: #black;
			species visitor aspect: base;
			species party_place aspect: base;
			species drinks_chill_place aspect: base;
			species food_court aspect: base;
			species gambling_area aspect: base;
			species concert_stage;
			
		}
		
		display chart {
	    	chart "Chart1" type: series style: spline {
	    		
	    		data "happiness" value:happiness_level_map.values color:#black;
	    	}
		}
		
		display chart_display{
	    	chart "Chart2" type: histogram style: spline {
	    		
	    		data "" value:drunk_level_map.values color:#blue;
	    	}
		}
		display pie_display{
	    	chart "Chart2" type: pie style: spline {
	
	    		data "partyEnthusiast" value: partyEnthusiast_number color: #red;
				data "ChillPerson" value: chillPerson_number color: #blue;
				data "normal" value: gambler_number color: #yellow;
				data "gambler" value: normal_number color: #green;
				data "weird" value: weird_number color: #black;
	    		
	    		
	    	}
		}
		display pie_display_gambling{
	    	chart "Chart2" type: pie style: spline {
	
	    		data "total gambling people" value: gambling_people color: #red;
				data "gambling winners" value: gambling_winners color: #blue;
					
	        		
	        	}
	    	}    	    	
	    	
	    	}
	    	
		
	}
	
