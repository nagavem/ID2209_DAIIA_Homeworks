/***
* Name: Festival
* Author: Nagasudeep Vemula,Ayushi Shah
* Description: Festival Scenario with the challenge portion of the Security agent for bad guests and inclusion of Guest Memory
***/

model Festival

/* Insert your model definition here */

global{
	
	//Configuring the values
	
	int guestNumber<- 15;
	int infoCenter<-1;
	int foodStoreNumber<-3;
	int drinkStoreNumber<-3;
	point infoCenterLocation <- {40,40};
	int infoCenterSize<- 5;
	float guestSpeed <- 0.5;
	
	//The rate at which guests grow hungry or thirsty
	int hungerRate <- 5;
	
	
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
	}
	
}

/*
 * Max value for both thirst and hunger is 100
 * Guests enter with a random value for both between 50 and 100
 * Guests will wander about until they get either thirsty or hungry, at which point they will start heading towards the info center 
 * for guidelines on reaching the food and drinks stores
 */

species guest skills:[moving]
{
	float thirst<- rnd(50)+50.0;
	float hunger<- rnd(50)+50.0;
	//int guestId<-
	
	rgb color<- #red;
	
	
	building target<- nil;
	
	aspect default
	{
		draw sphere(2) at: location color:color;
	}
	
	/* 
	 *  For Inducing thirst and hunger with a random value between 0 and 0.5
	 * Once agent's thirst or hunger reaches below 25, they will head towards info/Store
	 */	
	reflex thirstyHungry{
		
		//Decrement thirst and hunger counters
		thirst<- thirst-rnd(hungerRate);
		hunger<- hunger-rnd(hungerRate);
		
		//In case of thirst and hunger this condition enables the guest to prioritise hunger and proceed
		bool getFood<- false;
		
		if(target=nil and (thirst < 25 or hunger < 25)){
			string destinationMessage<- name;
			//write destinationMessage;
			if(thirst < 25 and hunger < 25)
			{
				destinationMessage <- destinationMessage + " is thirsty and hungry,";
			}
			else if(thirst < 25)
			{
				destinationMessage <- destinationMessage + " is thirsty,";
			}
			else if(hunger < 25)
			{
				destinationMessage <- destinationMessage + " is hungry,";
				getFood <- true;
			}
			
			color<- #blue;
			target <- one_of(infoCenterSp);
			//color<- #red;
			
			destinationMessage <- destinationMessage + " heading to " + target.name;
			write destinationMessage;
			
		}
	} 
	
	//Default guest behaviour at festival
	reflex beFestive when: target=nil
	{
		do wander;
		color<- #red;
	}
	
	//Move towards target on acquiring target
	reflex moveToTarget when: target!=nil
	{
		do goto target:target.location speed:guestSpeed;
	} 
	
	
	/* 
	 * Guest arrives at the information center
	 * It is assumed the guests will only head to the info center when either thirsty or hungry
	 * 
	 * The guests will prioritize the attribute that is lower for them,
	 * if tied then thirst goes first and guest decides to go for a drink
	 */
	 
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
				myself.thirst <- 1500.0;
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

/* InfoCenter serves information with the ask function */
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
	
}

/* 
 * These stores replenish guests' hunger. The information center keeps a list of food stores.
 */
 
species foodStore parent: building
{
	bool sellsFood <- true;
	
	aspect default
	{
		draw pyramid(5) at: location color: #green;
	}
}


/* 
 * These stores replenish guests' thirst. The info center keeps a list of drink stores.
 */
 
species drinkStore parent: building
{
	bool sellsDrink <- true;
	
	aspect default
	{
		draw pyramid(5) at: location color: #gold;
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
		}
	}
}