/***
* Name: Task 2
* Author: ayushi and Naga
* Description: Define utilities for stages and guest chooses stage based on preference 
* 
***/
//ligthing, rock, edm, hiphop, pop, acoustics
model Task2

/* Insert your model definition here */

global 
{
	
	list<point> stageLocation;
	list<string> locationName;
	int NumberOfGuests <- rnd(10,20);
	init
	{

		create Stage number: 1
		{
			location <- {15, 50};
			add location to: stageLocation;	
			add name to: locationName;	
		}
		create Stage number: 1
		{
			location <- {50,30};
			add location to: stageLocation;	
			add name to: locationName;	
		}
		create Stage number: 1
		{
			location <- {50, 75};
			add location to: stageLocation;	
			add name to: locationName;	
		}
		create Stage number: 1
		{
			location <- {80, 50};
			add location to: stageLocation;	
			add name to: locationName;	
		}
		create Guest number: NumberOfGuests
		{
			location <- {10 + rnd(80), 10 + rnd(80)};	
		}
		create Leader number:1
		{
			//location <- {1,50};
		}
		

	}
}


species Leader skills:[fipa]{

	list<int> goals <- [];
	
	reflex gotoTarget when: (!empty(informs))
		{
			list guestIntendedGoals <- informs;
			loop a over: guestIntendedGoals
				{
				add int(a.contents[0]) to: goals;									
				}
			do start_conversation with: [ to::list(Guest), protocol:: 'no-protocol', performative :: 'request', contents::goals];
				goals <- [];
	}

	
}


species Guest skills: [fipa, moving] {
	point preferredStage;
	float ligthingPreference <- rnd(10)/10;
	float rockPreference <- rnd(10)/10;
	float hipHopPreference <- rnd(10)/10;
	float popPreference <- rnd(10)/10;
	float acousticsPreference <- rnd(10)/10;
	float edmPreference <- rnd(10)/10;
	float crowdPreference <- rnd(10)/10;
	list<float> utilities;
	bool startConversation <- true; 
	Stage stage1;
	rgb color <- #darkred;
	
	point encoreLocation;


	
	reflex getParameters when: (!empty(cfps))
	{
		list<string> names <-[];
		list<float> ligthing <-[];
		list<float> edm <- [];
		list<float> rock <- [];
		list<float> hiphop <- [];
		list<float> acoustics <- [];
		list<float> pop <- [];
		utilities <- []; 
		list getparameters <- cfps;
		point preferredStage <- nil;
		
		
	
		if length(getparameters) = length(stageLocation)
			{
					
			loop a over: getparameters
			{			
			add (string(a.contents[0])) to: names;
			add (float(a.contents[1])) to: ligthing;			
			add (float(a.contents[2])) to: edm;
			add (float(a.contents[3])) to: rock;
			add (float(a.contents[4])) to: hiphop;
			add (float(a.contents[5])) to: acoustics;
			add (float(a.contents[6])) to: pop;
			}
			
			loop i from: 0 to: (length(getparameters) - 1)
			{
				float utilitynew <- rockPreference * edm[i] + ligthingPreference * ligthing[i] + hipHopPreference * rock[i] + popPreference * hiphop[i] + acousticsPreference * acoustics[i] + edmPreference * pop[i] ; 
				add utilitynew to: utilities;
				
			}
		
			int goal <- utilities index_of (max(utilities));
			float maxutility <- utilities[goal];
			do start_conversation with: [ to :: list(Leader), protocol :: 'no-protocol', performative :: 'inform', contents :: [goal, self.name, maxutility]];	
						
			loop a over: getparameters
			{
				do end_conversation with:[message:: a, contents::['The favoured place for all the guests in the list']];	
			}
				

			
			}
		}
	
	reflex askAttributes when: startConversation = true
	{
	do start_conversation with: [ to :: list(Stage), protocol :: 'no-protocol', performative :: 'cfp', contents :: ['getattributes'] ];	
	startConversation <- false;
	}
	
	reflex CrowdMassUtility when: (!empty(informs))
	{
		list Crowdlevel <- informs[0].contents[0];
		
		if crowdPreference < 0.5
		{
			loop a from: 0 to: (length(Crowdlevel) -1)
			{
				if string(Crowdlevel[a])as_int 10 = 1
				{
					Crowdlevel[a] <- 0;
				}else{
					Crowdlevel[a] <- 1;
				}
			}			
		}
		list newutilities <-[ ];
		loop a from: 0 to: length(utilities) - 1
		{
			if crowdPreference < 0.5
			{
			add (float(utilities[a]) + float(Crowdlevel[a]) * (1- crowdPreference - 0.5)) to: newutilities;	
			}else
			{
			add (float(utilities[a]) + float(Crowdlevel[a]) * (crowdPreference - 0.5)) to: newutilities;	
			}
			
		}
		
		int goal <- newutilities index_of (max(newutilities));
		float maxutility <- newutilities[goal]; 
		do start_conversation with: [ to :: list(Leader), protocol :: 'no-protocol', performative :: 'inform', contents :: [goal, self.name, maxutility]];	
		
	}
	
	reflex getpreferredStage when: (!empty(requests))
	{		
		write 'The favourable places of all guests in a list';
		list goals <- requests[0].contents;
		write goals;
		int a <- index_of(Guest, self);
		write name +' will move to '+ locationName[goals [a]] + ' based on the utility calculation.' ;
		preferredStage <- stageLocation[goals [a]];
	
	}

	
	reflex goToTarget when: preferredStage != nil
	{		
		
		if (location distance_to preferredStage) < 10.0
		{
			do wander;
		}
		else
		{
			do goto target: preferredStage speed: 5.0;	
		}
	}	

	aspect default
	{
		draw sphere(1.5) at: location color: color ;
	}
}
species Stage skills: [fipa, moving] {
	rgb myColor <- #blue;
	bool begin <- true;
	float newact <- 25.0;
	float edm <- rnd(10)/10;
	float ligthing <- rnd(10)/10;
	float rock <- rnd(10)/10;
	float hiphop <- rnd(10)/10;
	float acoustics <- rnd(10)/10;
	float pop <- rnd(10)/10;
	Guest appearance;
	//encore ds;
	
	
	reflex hostNewAct when: time = newact 
	{
		ligthing <- 1/(1 + rnd(9));
		edm <- 1 / (1 + rnd(9));
		rock <- 1/(1 + rnd(9));
		hiphop <- 1/(1 + rnd(9));
		acoustics <- 1/(1 + rnd(9));
		pop <- 1/(1 + rnd(9));	
		
		do start_conversation with: [ to::list(Guest), protocol:: 'no-protocol', performative :: 'cfp', contents::[self.name, ligthing, edm, rock, hiphop, acoustics, pop]];
		
		newact <- time + 25.0;
	} 

	
	
	

	reflex sendParameters when: (!empty(cfps)) 
		{
		loop a over: cfps
		{
		if a.contents = ['getattributes']
			{
			do cfp with:[message:: a, contents::[self.name, ligthing, edm, rock, hiphop, acoustics, pop]];	
			
			}	
		}			
		}

	
	aspect default
	{
		draw cube (5) at: location color: myColor; 
	}
}




experiment main type: gui {
	output {
		display map type: opengl 
		{
			species Guest;
			species Stage;
			species Leader;
			
		}
	}
}