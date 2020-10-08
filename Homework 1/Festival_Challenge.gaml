/***
* Name: Festival
* Author: Ayushi and Nagasudeep
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Challenge

/* Insert your model definition here */

global{
	int guestNumber<- 15;
	int infoCenter<-1;
	int foodStoreNumber<-3;
	int drinkStoreNumber<-3;
	point infoCenterLocation <- {40,40};
	int infoCenterSize<- 5;
	float guestSpeed <- 0.5;
	int hungerRate <- 5;
	float CopSpeed <- guestSpeed * 1.5;
	
	
	init
	{
		/* Create GuestNumber (defined above) amount of Guests */
		create guest number: guestNumber
		{
			
		}
		
				
		/*
		 * Number of stores is defined above 
		 */
		create foodStore number: foodStoreNumber
		{

		}
		
		/*
		 * Number of stores id defined above 
		 */
		create drinkStore number: drinkStoreNumber
		{

		}
		
		/*
		 * location is 50,50 to put the info center in the middle
		 */
		create infoCenterSp number: 1
		{
			location <- infoCenterLocation;
		}
		
		create Security number: 1
		{

		}
	}
	
}

species guest skills:[moving]
{
	float thirst<- rnd(50)+50.0;
	float hunger<- rnd(50)+50.0;
	
	int guestId <- rnd(1000,10000);
	bool isBad <- flip(0.2);
	rgb color<- #red;
	list<building> guestBrain;
	
	building target<- nil;
	
	aspect default
	{
		if(isBad) {
			color <- #darkred;
		}
		draw sphere(2) at: location color: color;
	}
	
	reflex thirstyHungry{
		thirst<- thirst-rnd(hungerRate);
		hunger<- hunger-rnd(hungerRate);
		
		bool getFood<- false;
		
		if(target=nil and (thirst < 25 or hunger < 25)){
			string destinationMessage<- name;
			bool temp<- false;
			list<guest> nearbyGests<- guest at_distance(5);
			write "###################################################nearbyguests"+nearbyGests ;
			//write destinationMessage;
			if(thirst < 25 and hunger < 25)
		
			{
				ask guest at_distance(5)
				{
					if (length(self.guestBrain) != 0)
					{
						loop j from: 0 to: length(guestBrain)-1
						{
							//write "###################### in loop + j sells Drink" +name;
						
							if (guestBrain[j].sellsDrink = true)
							{
								write "sellsDrink true";
								temp<-true;
								if(isBad=false){
									myself.color <- #gold;	
								}
								
								//target <- guestBrain[j];
								myself.guestBrain <+ guestBrain[j]; 
								destinationMessage <- destinationMessage + " took information from" +name;
								write destinationMessage;
								break;
							}
						}
					}
				}
				destinationMessage <- destinationMessage + " is thirsty and hungry,";
			}
			else if(thirst < 25)
			{
				ask guest at_distance(5)
				{
					if (length(self.guestBrain) != 0)
					{
						loop j from: 0 to: length(guestBrain)-1
						{
							//write "###################### in loop + j sells Drink" +name;
							
							if (guestBrain[j].sellsDrink = true)
							{
								write "sellsDrink true";
								temp<-true;
								if(isBad=false){
									myself.color <- #gold;
								}
									
								//target <- guestBrain[j];
								myself.guestBrain <+ guestBrain[j];
								destinationMessage <- destinationMessage + " took information from" +name;
								write destinationMessage;
								break;
							}
						}
					}
				}
				
				destinationMessage <- destinationMessage + " is thirsty,";
			}
			else if(hunger < 25)
			
			{
				
				ask guest at_distance(5)
				{
					if (length(self.guestBrain) != 0)
					{
						loop j from: 0 to: length(guestBrain)-1
						{
							//write "###################### in loop + j sells Food " + name;
							
							if (guestBrain[j].sellsFood = true)
							{
								write "sellsFood true";
								temp<-true;
								if(isBad=false){
								myself.color <- #green;
								}
								//target <- guestBrain[j];
								myself.guestBrain <+ guestBrain[j];
								destinationMessage <- destinationMessage + " took information from" +name;
								write destinationMessage;
								break;
							}
						}
					}
				}
				if(temp=false){
					destinationMessage <- destinationMessage + " is hungry,";
					getFood <- true;
				}
			}
			
			//color<- #blue;
			//target <- one_of(infoCenterSp);
			//color<- #red;
			
			//bool useBrain <- flip(0.5);
			//if(length(guestBrain) > 0 and useBrain = true)
			if(length(guestBrain) > 0)
			{

				loop i from: 0 to: length(guestBrain)-1
				{
					// If user is hungry, ask guestBrain for food stores,
					// in the case of draw and otherwise ask for drink stores
					if(getFood = true and guestBrain[i].sellsFood = true)
					{
						float gain<- ((location distance_to infoCenterLocation)+ (infoCenterLocation distance_to guestBrain[i].location)) - (location distance_to guestBrain[i].location);
						write "#################################gain"+gain;
						target <- guestBrain[i];
						destinationMessage <- destinationMessage + " (brain used)";
						
						// Set getFood back to false, so we'll continue to prefer drink in the future too
						getFood <- false;
						break;
					}
					else if(getFood = false and guestBrain[i].sellsDrink = true)
					{
						target <- guestBrain[i];
						destinationMessage <- destinationMessage + " (brain used)";
						break;
					}
				}
			}
			
			if(target = nil)
			{
				//color<- #blue;
				target <- one_of(infoCenterSp);	
			}
			
			destinationMessage <- destinationMessage + " heading to " + target.name;
			write destinationMessage;
			
		}
		
		
		
	} 
	
	reflex beFestive when: target=nil
	{
		do wander;
		color<- #red;
	}
	
	reflex moveToTarget when: target!=nil
	{
		do goto target:target.location speed:guestSpeed;
	} 
	
	reflex reachInfoCenter when: target!=nil and target.location= infoCenterLocation and location distance_to(target.location) < infoCenterSize
	{
		string destinationString <- name  + " getting "; 
		ask infoCenterSp at_distance infoCenterSize
		{
			if(myself.thirst <= myself.hunger)
			{
				
				myself.target <- drinkStores[rnd(length(drinkStores)-1)];
				myself.color<- #gold;
				destinationString <- destinationString + "drink at ";
			}
			else
			{
				myself.target <- foodStores[rnd(length(foodStores)-1)];
				myself.color<- #green;
				destinationString <- destinationString + "food at ";
			}
			
			if(length(myself.guestBrain) < 2)
			{
				myself.guestBrain <+ myself.target;
				destinationString <- destinationString + "(added to brain) ";
			}
			
			write destinationString + myself.target.name;
		}
	}
	
	reflex isThisAStore when: target != nil and location distance_to(target.location) < 2
	{
		ask target
		{
			string replenishString <- myself.name;	
			if(sellsFood = true)
			{
				myself.hunger <- 1000.0;
				myself.target<-nil;
				myself.color<- #red;
				replenishString <- replenishString + " ate food at " + name;
			}
			else if(sellsDrink = true)
			{
				myself.thirst <- 1000.0;
				myself.target<-nil;
				myself.color<- #red;
				replenishString <- replenishString + " had a drink at " + name;
			}
			
			write "replenishString"+replenishString;
		}
		
		target <- nil;
	}
	 
	
}

species building
{
	bool sellsFood<- false;
	bool sellsDrink<- false;	
} 

species infoCenterSp parent: building
{
	list<foodStore> foodStores<- (foodStore at_distance 1000);
	list<drinkStore> drinkStores<- (drinkStore at_distance 1000);
	
	bool hasLocations <- false;
	
	reflex listStoreLocations when: hasLocations = false
	{
		ask foodStores
		{
			write "Food store at:" + location; 
		}	
		ask drinkStores
		{
			write "Drink store at:" + location; 
		}
		
		hasLocations <- true;
	}
	
	aspect default
	{
		draw cube(5) at: location color: #blue;
	}
	
	reflex checkForBadGuest
	{
		ask guest at_distance infoCenterSize
		{
			if(self.isBad)
			{
				guest badGuest <- self;
				ask Security
				{
					if(!(self.targets contains badGuest))
					{
						self.targets <+ badGuest;
						write 'InfoCenter found a bad guest (' + badGuest.name + '), sending Cop after it';	
					}
				}
			}
		}
	}
	
}

species foodStore parent: building
{
	bool sellsFood <- true;
	
	aspect default
	{
		draw pyramid(5) at: location color: #green;
	}
}

species drinkStore parent: building
{
	bool sellsDrink <- true;
	
	aspect default
	{
		draw pyramid(5) at: location color: #gold;
	}
}

species Security skills:[moving]
{
	list<guest> targets;
	aspect default
	{
		draw cube(5) at: location color: #black;
		//write "cop drawn";
	}
	
	reflex catchBadGuest when: length(targets) > 0
	{
		//this is needed in case the guest dies before cop catches them
		if(dead(targets[0]))
		{
			targets >- first(targets);
		}
		else
		{
			do goto target:(targets[0].location) speed: CopSpeed;
		}
	}
	
	reflex badGuestCaught when: length(targets) > 0 and !dead(targets[0]) and location distance_to(targets[0].location) < 0.2
	{
		ask targets[0]
		{
			write name + ': exterminated by cop!';
			do die;
		}
		targets >- first(targets);
	}
}

experiment main type: gui
{
	
	output
	{
		display map type: opengl
		{
			species guest;
			species foodStore;
			species drinkStore;
			species infoCenterSp;
			species Security;
		}
	}
}