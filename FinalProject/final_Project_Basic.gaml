/***
* Name: Basic
* Author: Naga And Ayushi
* Description: Implementation of the festival simulation with different agent interactions
***/


model Basic

global {
	
	int number_of_people <- 50;
	
	int total_conversations <- 0;
	int total_denies <- 0;
	int partied <- 0;
	int chilled <- 0;
	int ate <- 0;
	int gambled <- 0;
	map<string, int> happiness_level_map;
	list<int>all_happiness_values;
	
	
	//rgb my_color <- #red;
	
	init{
		create visitor number: number_of_people;
		
		create party_place number: 1
				{
					//location <- {25,25};
		
				}
				
		create drinks_chill_place number: 1
				{
					//location <- {75,25};
				}
				
		create food_court number: 1
				{
					//location <- {25,75};
				}
				
		create gambling_area number: 1
				{
					//location <- {75,75};
				}
	}
}

species visitor skills:[moving, fipa] {
	
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
	}
	}
	// Attributes (at least 3):
	int wealthy <- rnd(0, 9);
	bool talkative <- flip(0.5);
	int generous <- rnd(0, 9);
	
	int food_level <- rnd(150, 200) min: 0 update: food_level - 1;
	
	string status <- 'wandering';
	
	string present_desire <- nil;
	int desire_completion <- 0;
	
	point target <- nil;
	point wander_point <- self.location;

	reflex go_wander when: target = nil and present_desire = 'wander' {
		// to keep it within the grid limits:
		float x_wander_min <- (self.location.x - 10) < 0 ? 0 : self.location.x - 10;
		float x_wander_max <- (self.location.x + 10) > 100 ? 100 : self.location.x + 10;
		float y_wander_min <- (self.location.y - 10) < 0 ? 0 : self.location.y - 10;
		float y_wander_max <- (self.location.y + 10) > 100 ? 100 : self.location.y + 10;		
		
		desire_completion <- desire_completion + 1;
		if (desire_completion > 30 and self.location = wander_point) {
			present_desire <- nil;
			wander_point <- self.location;
			desire_completion <- 0;
			return;
		}
		
		if (self.location = wander_point) {
			wander_point <- point(rnd(x_wander_min, x_wander_max), rnd(y_wander_min, y_wander_max));
		}
		do goto target: wander_point;
	}
	
	reflex moveToTarget when: target != nil {
		if(target = location) {
			target <- nil;
		}
		do goto target: target;
	}
	
	
	reflex eat when: food_level = 0 {
		point food_place_loc;
		ask food_court{
			food_place_loc<-location;
			
		}
		if (status != 'walking to eat') {
			// Top left cube is food area
			target <- food_place_loc;	
		}
		status <- 'walking to eat';
		if (self.location = target) {
			target <- nil;
			food_level <- rnd(150, 200);
			ate <- ate + 1;
			status <-'wandering';
			wander_point <- self.location;
		}
	}
	
	reflex get_a_present_desire when: present_desire = nil {
		int roll <- rnd(0, 99);
		
		switch agent_type {
			match 'normal' {
				switch roll {
					match_between [0, 24] {present_desire <- 'party';}		// 25% to party
					match_between [25, 34] {present_desire <- 'chill';}		// 10% to chill
					match_between [35, 39] {present_desire <- 'gamble';}		// 5% to gamble
					default {present_desire <- 'wander';}						// 60% to wander
				}
			}
			match 'partyEnthusiast' {
				switch roll {
					match_between [0, 39] {present_desire <- 'party';}		// 40% to party
					match_between [40, 54] {present_desire <- 'chill';}		// 15% to chill
//					match_between [35, 39] {present_desire <- 'gamble';}		// 0% to gamble
					default {present_desire <- 'wander';}						// 45% to wander
				}
			}
			match 'chillPerson' {
				switch roll {
					match_between [0, 14] {present_desire <- 'party';}		// 15% to party
					match_between [15, 49] {present_desire <- 'chill';}		// 35% to chill
					match_between [50, 59] {present_desire <- 'gamble';}		// 10% to gamble
					default {present_desire <- 'wander';}						// 40% to wander
				}
			}
			match 'gambler' {
				switch roll {
					match_between [0, 9] {present_desire <- 'party';}		// 10% to party
					match_between [10, 19] {present_desire <- 'chill';}		// 10% to chill
					match_between [20, 59] {present_desire <- 'gamble';}		// 30% to gamble
					default {present_desire <- 'wander';}						// 40% to wander
				}
			}
			match 'weird' {
				switch roll {
					match_between [0, 4] {present_desire <- 'party';}		// 5% to party
					match_between [5, 9] {present_desire <- 'chill';}		// 5% to chill
					match_between [10, 14] {present_desire <- 'gamble';}		// 5% to gamble
					default {present_desire <- 'wander';}						// 85% to wander
				}
			}
			default {}
		}
	}
	
	reflex party when: present_desire = 'party' and food_level != 0 {
		point party_place_loc;
		ask party_place{
			party_place_loc<-location;
			
		}
		if (status != 'walking to party' and status != 'partying') {
			target <- party_place_loc;	
		}
		
		if (status != 'partying') {
			status <- 'walking to party';	
		}
		
		if (self.location = target) {
			target <- nil;
			status <-'partying';
		}
		
		if (status = 'partying') {
			desire_completion <- desire_completion + 1;
			do wander;
			
			if (desire_completion = 30) {
				desire_completion <- 0;
				present_desire <- nil;
				partied <- partied + 1;
				status <- 'wandering';
				wander_point <- self.location;
			}
		}
		
	}
	
	reflex chill when: present_desire = 'chill' and food_level != 0 {
		point chill_place_loc;
		ask drinks_chill_place{
			chill_place_loc<-location;
			
		}
		if (status != 'walking to chill' and status != 'chilling') {
			target <- {75, 25};	
		}
		
		if (status != 'chilling') {
			status <- 'walking to chill';	
		}
		
		if (self.location = target) {
			target <- nil;
			status <-'chilling';
		}
		
		if (status = 'chilling') {
			desire_completion <- desire_completion + 1;
			do wander;
			
			if (desire_completion = 30) {
				desire_completion <- 0;
				present_desire <- nil;
				chilled <- chilled + 1;
				status <- 'wandering';
				wander_point <- self.location;
			}
		}
	}
	
	reflex gamble when: present_desire = 'gamble' and food_level != 0 {
		point gamble_place_loc;
		ask gambling_area{
			gamble_place_loc<-location;
			
		}
		if (status != 'walking to gamble' and status != 'gambling') {
			target <- gamble_place_loc;	
		}
		
		if (status != 'gambling') {
			status <- 'walking to gamble';	
		}
		
		if (self.location = target) {
			target <- nil;
			status <-'gambling';
		}
		
		if (status = 'gambling') {
			desire_completion <- desire_completion + 1;
			do wander;
			
			if (desire_completion = 30) {
				desire_completion <- 0;
				present_desire <- nil;
				gambled <- gambled + 1;
				status <- 'wandering';
				wander_point <- self.location;
			}
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
					//if self.location.x >= party_place_loc.x and self.location.x < 27 and self.location.y > 73 and self.location.y < 77 {
						// party
						//if (name = 'visitor0') {write '' + one_inform.contents[0] +  '(' + one_inform.contents[2] + ') wants to party with me!';}
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
							//if (name = 'visitor0') {write 'PARTY!';}
						} else {
							write name+"is a"+agent_type+"doesnt want to party with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1];
							do cancel message: one_inform contents: ['No I am not interested'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
							//if (name = 'visitor0') {write 'No, yuck.';}
						}
						do end_conversation message: one_inform contents: ['Action'];
						
					}
					
					else if (self.location distance_to chill_place_loc <=5){
					
						// chill
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
						// food
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
						// gambling
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
						// party
						if ((int(one_inform.contents[2])>=5 or int(one_inform.contents[4])>=5)) {
							write name+" is a "+ agent_type +" partying with "+ one_inform.contents[1]+" whose type is "+ one_inform.contents[1];
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
							write name+" is a "+ agent_type +" doesnt want to party with "+ one_inform.contents[1]+" who is less generous and less talkative " ;
							
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
						
					}
					//chill location-----------------------------------------------------------------------------------------
					else if (self.location distance_to chill_place_loc <=5){
					
						if (int(one_inform.contents[2])>=5 and (one_inform.contents[1]!='gambler' and one_inform.contents[1]!='weird')){ 
							write name+" is a "+ agent_type+" chilling with "+ one_inform.contents[1]+" whose type is "+ one_inform.contents[1];
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
							write name+"is a"+agent_type+"doesnt want to chill with "+ one_inform.contents[1]+"who is less generous and a gambler or weirdo" ;
							
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
						// food
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
					//gamble--------------------------------------------------------------------------------------------------------
					else if (self.location distance_to gamble_place_loc <=5){
						// gambling
						if (int(one_inform.contents[3]) >= 5 and wealthy >= 5) {
							write name+"is a"+agent_type+"gambling with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1]+ "And who is very wealthy";
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
	
						} else {
							write name+"is a"+agent_type+"doesnt want to gamble with "+ one_inform.contents[1]+"who is not wealthy enough";
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
				write name+"is a"+agent_type+"and is not one for partying too much" ;
						do cancel message: one_inform contents: ['No'];
						total_denies <- total_denies + 1;
						happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
						do end_conversation message: one_inform contents: ['Action'];
						
					}
					else if (self.location distance_to chill_place_loc <=5){
					    write name+"is a"+agent_type+"chilling with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1];
						do agree message: one_inform contents: ['Yes'];
						total_conversations <- total_conversations + 1;
						happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
	
						
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
						// gambling
						if (int(one_inform.contents[3]) >= 3 and wealthy >= 6) {
							write name+"is a"+agent_type+"gambling with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1]+ "And who is wealthy";
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
						} else {
							write name+"is a"+agent_type+"doesnt want to gamble with "+ one_inform.contents[1]+"who is not wealthy enough";
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
					
						// party
						if (int(one_inform.contents[2])>=5 and one_inform.contents[1] != 'weirdo') {
							write name+"is a"+agent_type+"partying with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1];
							
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						} else {
							write name+"is a"+agent_type+"and is not one for partying too much" ;
							
							do cancel message: one_inform contents: ['No'];
							total_denies <- total_denies + 1;
							happinessLevel<- -5;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						}
						do end_conversation message: one_inform contents: ['Action'];
						
					}
					else if (self.location distance_to chill_place_loc <=5){
					
						// chill
						if ((int(one_inform.contents[4]) <= 5) and one_inform.contents[1] != 'weirdo' and wealthy = 0) {
												    write name+"is a"+agent_type+"chilling with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1];
							
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
					
						// food
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
					
						// gambling
						if (int(one_inform.contents[3]) >= 5 and wealthy >= 5) {
							write name+"is a"+agent_type+"gambling with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1]+ "And who is wealthy";
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						} 
						else {
							write name+"is a"+agent_type+"doesnt want to gamble with "+ one_inform.contents[1]+"who is not wealthy enough";
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
				
						// party
					write name+"is a"+agent_type+"partying with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1];
						do agree message: one_inform contents: ['Yes'];
						total_conversations <- total_conversations + 1;
						happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
						
						do end_conversation message: one_inform contents: ['Action'];
						
					}
					
					else if (self.location distance_to chill_place_loc <=5){
					
						// chill
				 write name+"is a"+agent_type+"chilling with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1];
						
						do agree message: one_inform contents: ['Yes'];
						total_conversations <- total_conversations + 1;
						happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
						
						
						do end_conversation message: one_inform contents: ['Action'];
					}
					
					
					else if (self.location distance_to food_place_loc <=5){
						// food
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
					
						// gambling
						
						if (int(one_inform.contents[3]) >= 5) {
							write name+"is a"+agent_type+"gambling with "+ one_inform.contents[1]+"whose type is "+one_inform.contents[1]+ "And who is wealthy";
							
							do agree message: one_inform contents: ['Yes'];
							total_conversations <- total_conversations + 1;
							happinessLevel<- 9;
								happiness_level_map[name]<- happiness_level_map[name]+happinessLevel;
								happiness_level_map[one_inform.contents[0]]<- happiness_level_map[one_inform.contents[0]]+happinessLevel;
							
							
						} else {
							write name+"is a"+agent_type+"doesnt want to gamble with "+ one_inform.contents[1]+"who is not wealthy enough";
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
	aspect base{
		draw circle(15) color:#blue;		
	}
}

experiment my_experiment type: gui {

	output {
		display map_3D type: opengl{
			//grid festival_map lines: #black;
			species visitor aspect: base;
			species party_place aspect: base;
			species drinks_chill_place aspect: base;
			species food_court aspect: base;
			species gambling_area aspect: base;
		}
		
		display chart {
        	chart "Chart1" type: series style: spline {
//     		   	data "Total amount of c	onversations" value: total_conversations color: #darkgreen;
//        		data "Total amount of denied conversations" value: total_denies color: #darkred;
        		//data 'Partied' value: partied color: #green;
        		//data 'Chilled' value: chilled color: #red;
        		//data 'Ate' value: ate color: #blue;
        		//data 'Gambled' value: gambled color: #yellow;
        		
        		data "happiness" value:happiness_level_map.values color:#black;
        	}
    	}
	}
}