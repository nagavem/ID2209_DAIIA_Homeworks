/***
* Name: AuctionCreative
* Author: Naga and Ayushi
* Description: Creative Implementation 

* Tags: Tag1, Tag2, TagN
***/

model AuctionCreative

global 
{
	
	int guestNumber <- rnd(20)+20;
	int vipGuestNumber <- rnd(10)+5;
	
	float guestSpeed <- 0.5;
	
	
	point auctionerMasterLocation <- {-10,50};
	list<string> itemsAvailable <- ["instruments","signed shirts","Memorabillia", "posters and artwork"];
	
	// Time when auctioneers are created
	int auctionCreationMin <- 0;
	int auctionCreationMax <- 50;
	
	// Guest accepted price range min and max
	int guestAcceptedPriceMin <- 100;
	int guestAcceptedPriceMax <- 1500;
	
	
	int engAuctionRaiseMin <- 30;
	int engAuctionRaiseMax <- 60;
	// The initial price of the item to sell
	int auctionerEngPriceMin <- 0;
	int auctionerEngPriceMax <-1500;
	
	
	int dutchAuctionDecreaseMin <- 5;
	int dutchAuctionDecreaseMax <- 15;
	// The initial price of the item to sell, set above the max price so that no guest immediately wins
	int auctionerDutchPriceMin <- 1504;
	int auctionerDutchPriceMax <-1600;
	// Minimum price of the item, if the bids go below this the auction fails
	int auctionerMinimumValueMin <- 100;
	int vipAuctionMinValue<- 1400;
	int auctionerMinimumValueMax <- 300;
	
	list<string> auctionTypes <- ["Dutch"];

	
	
	init
	{
		/* Create guestNumber (defined above) amount of Guests */
		create Guest number: guestNumber
		{
			// Each guest prefers a random item
			preferredItem <- itemsAvailable[rnd(length(itemsAvailable) - 1)];
		}
		
		create AuctionerMaster
		{
			
		}
		create vipGuest number: vipGuestNumber{
			preferredItem <- itemsAvailable[rnd(length(itemsAvailable) - 1)];
			
		}
	}
	
}

species Guest skills:[moving, fipa]
{
	
	
	bool isVIP <- flip(0.2);
	
	bool wonAuction <- false;
	rgb color <- #red;
	// Default color of guests
	
	// This is the price at which the guest will buy merch, set in the configs above
	int guestMaxAcceptedPrice <- rnd(guestAcceptedPriceMin,guestAcceptedPriceMax);
	
	Auctioner targetAuction;
	Auctioner target;
	
	string preferredItem;
	
	aspect default
	{
		draw sphere(2) at: location color: color;

		if (wonAuction = true)
		{
			if(preferredItem = "instruments")
			{
				
				draw cube(1.2) at: location + point([2.1, 0.0, 2.0]) color: #purple;
			}
			else if(preferredItem = "signed shirts")
			{
				draw pyramid(1.2) at: location + point([0.0, 0.0, 3.5]) color: #orange;
			}
			else if(preferredItem = "Memorabillia")
			{
				draw cylinder(2.01, 1.5) at: location + point([0.0, 0.0, 1.0]) color: #lime;
			}
			else if(preferredItem = "posters and artwork")
			{
				draw cylinder(2.01, 1.5) at: location color: #pink;
			}
		}
	}
	
	reflex inAuction when: targetAuction != nil
	{
		
		if(location distance_to(targetAuction.location) > 9)
		{
			target <- targetAuction;
		}
		else
		{
			target <- nil;
		}
	}
	
	reflex beIdle when: target = nil
	{
		do wander;
	}
	
	reflex moveToTarget when: target != nil
	{
		do goto target:target.location speed: guestSpeed;
	}
	

	reflex listen_messages when: (!empty(cfps))
	{
		message requestFromInitiator <- (cfps at 0);
		// the request's format is as follows: [String, auctionType, soldItem, ...]
		if(requestFromInitiator.contents[0] = 'Start' and requestFromInitiator.contents[1] = preferredItem)
		{
			// If the guest receives a message from an auction selling its preferredItem,
			// the guest participates in that auction
			targetAuction <- requestFromInitiator.sender;

			// Send a message to the auctioner telling them the guest will participate
			
			// TODO: handle this better
			// Essentially add the guest to the interestedGuests list
//			if(self.isVIP){
//				write name + "is vip guest joins " + requestFromInitiator.sender + "'s auction for " + preferredItem;
//				targetAuction.vipGuests <+self;
//			}
//			else{
			write name + " joins " + requestFromInitiator.sender + "'s auction for " + preferredItem;
			targetAuction.interestedGuests <+ self;
			//}
			
			
		}
		//End of auction
		else if(requestFromInitiator.contents[0] = 'Stop' and requestFromInitiator.contents[0]='both')
		{
//			
			write name + ' knows the auction is over.';
			targetAuction <- nil;
			target <- nil;
			
		}
		
		else if(requestFromInitiator.contents[0] = 'Winner')
		{
			wonAuction <- true;
			write name + ' won the auction for ' + preferredItem;
			if(preferredItem = "Memorabillia")
			{
				write "Killer Purchase dude !!!";
			}
		}
	}
	
	
	reflex reply_messages when: (!empty(proposes))
	{
		message requestFromInitiator <- (proposes at 0);
		
		string auctionType <- requestFromInitiator.contents[1];
		if(auctionType = "Dutch")
		{
			int offer <- int(requestFromInitiator.contents[2]);
			if (guestMaxAcceptedPrice >= offer) {
				do accept_proposal with: (message: requestFromInitiator, contents: ["I, " + name + ", accept your offer of " + offer]);
			}
			else
			{
				do reject_proposal (message: requestFromInitiator, contents: ["I, " + name + ", am afraid I cannot accept that price!"]);	
				targetAuction <- nil;
				target <- nil;
			}
		}
	}
	
}
species AuctionerMaster skills:[fipa]
{
	bool auctionersCreated <- false;
	list<Auctioner> auctioners <- [];


	reflex createAuctioners when: !auctionersCreated and time rnd(auctionCreationMin, auctionCreationMax)
	{
		string genesisString <- name + " creating auctions: ";
		
		loop i from: 0 to: length(itemsAvailable)-1
		{
			create Auctioner
			{	
				location <- {rnd(100),rnd(100)};
				soldItem <- itemsAvailable[i];
				genesisString <- genesisString + name + " with " + itemsAvailable[i] + " ";
				myself.auctioners <+ self;
			}
		}
		write genesisString;
		auctionersCreated <- true;
	}	
}

species Auctioner skills:[fipa, moving]
{
	// Auction's initial size and color, location used in the beginning
	int mySize <- 10;
	rgb myColor <- #blueviolet;
	point targetLocation <- nil;
	
	// price of item to sell
	int auctionerDutchPrice <- rnd(auctionerDutchPriceMin, auctionerDutchPriceMax);
	int auctionerEngPrice <- rnd(auctionerEngPriceMin, auctionerEngPriceMax);
	// minimum price of item to sell. if max bid is lower than this, bid is unsuccessful
	int auctionerMinimumValue <- rnd(auctionerMinimumValueMin, auctionerMinimumValueMax);
	
	// vars related to start and end of auction
	bool auctionRunning <- false;
	bool startAnnounced <- false;
	//bool vipAuctionRunning<- false;
	string auctionType <- auctionTypes[rnd(length(auctionTypes) - 1)];
	int currentBid <- 0;
	string currentWinner <- nil;
	message winner <- nil;

	// The kind of an item the merchant is selling
	string soldItem <- "";
	// The guests participating in the auction
	list<Guest> interestedGuests;
	list<vipGuest> interestedVIPGuests;
	aspect
	{
		
		draw circle(mySize) color: myColor;
		//draw pyramid(mySize) color: myColor;
	}
	
	

	reflex sendStartAuction when: !auctionRunning and time >= 90 and targetLocation = nil and !startAnnounced
	{
		write name + " starting " + auctionType + " soon";
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ['Start', soldItem]);
		do start_conversation (to: list(vipGuest), protocol: 'fipa-propose', performative: 'cfp', contents: ['Start', soldItem]);
		startAnnounced <- true;
		
	}
	
	reflex guestsAreAround when: !auctionRunning and ((!empty(interestedGuests) and (interestedGuests max_of (location distance_to(each.location))) <= 13 ) or (!empty(interestedVIPGuests) and (interestedVIPGuests max_of (location distance_to(each.location))) <= 13))
	{
		write name + " guestsAreAround";
		auctionRunning <- true;
	}

	reflex receiveAcceptMessages when: auctionRunning and !empty(accept_proposals)
	{
		if(auctionType = "Dutch")
		{
			write name + ' receives accept messages';
			
			loop a over: accept_proposals {
				write name + ' got accepted by ' + a.sender + ': ' + a.contents;
				do start_conversation (to: a.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ['Winner']);
			}
			targetLocation <- auctionerMasterLocation;
			auctionRunning <- false;
			//end of auction
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop','both']);
			if(!empty(interestedVIPGuests)){
			do start_conversation (to: interestedVIPGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop','both']);
			}
			interestedGuests <- [];
			interestedVIPGuests <-[];
			do die;
		}
	}


	reflex receiveRejectMessages when: auctionRunning and !empty(reject_proposals)
	{
		if(auctionType = "Dutch")
		{
			write name + ' receives reject messages';
			
			auctionerDutchPrice <- auctionerDutchPrice - rnd(dutchAuctionDecreaseMin, dutchAuctionDecreaseMax);
			if(auctionerDutchPrice < auctionerMinimumValue)
			{
				targetLocation <- auctionerMasterLocation;
				auctionRunning <- false;

				write name + ' price went below minimum value (' + auctionerMinimumValue + '). No more auction for thrifty guests!';
				do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop','both']);
				if(!empty(interestedVIPGuests)){
				do start_conversation (to: interestedVIPGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop','both']);
				}
				interestedGuests <- [];
				interestedVIPGuests <-[];
				do die;
			}
			if(auctionerDutchPrice < vipAuctionMinValue and !empty(interestedVIPGuests))
			{
				targetLocation <- auctionerMasterLocation;
				

				write name + ' price went below minimum value for vip (' + vipAuctionMinValue + '). No more auction for vip guests!';
				//do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop','vip']);
				do start_conversation (to: interestedVIPGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop','vip']);
				
				interestedVIPGuests <-[];
				//interestedGuests <- [];
			}
			
		}

	}
	
	reflex sendAuctionInfo when: auctionRunning and time >= 50 and (!empty(interestedGuests) or !empty(interestedVIPGuests)){
		if(auctionType = "Dutch")
		{
			write name + ' sends the offer of ' + auctionerDutchPrice +' pesos to participants';
			if(!empty(interestedGuests)){
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'propose', contents: ['Buy my merch, peasant', auctionType, auctionerDutchPrice]);
			}
			if(!empty(interestedVIPGuests)){
			do start_conversation (to: interestedVIPGuests, protocol: 'fipa-propose', performative: 'propose', contents: ['Buy my merch, peasant', auctionType, auctionerDutchPrice]);
			}
		}
//		
	}	
}// Auctioner


species vipGuest skills:[moving, fipa]
{
	
	
	//bool isVIP <- flip(0.2);
	
	bool wonAuction <- false;
	rgb color <- #chocolate;
	// Default color of guests
	
	
	// This is the price at which the guest will buy merch, set in the configs above
	int guestMaxAcceptedPrice <- rnd(guestAcceptedPriceMin,guestAcceptedPriceMax);
	
	Auctioner targetAuction;
	Auctioner target;
	
	

	string preferredItem;
	
	aspect default
	{
		draw sphere(2) at: location color: color;

		if (wonAuction = true)
		{
			if(preferredItem = "instruments")
			{
				//point backPackLocation <- location + point([2.1, 0.0, 2.0]);
				//backPackLocation <- backPackLocation.x + 1; 
				draw cube(1.2) at: location + point([2.1, 0.0, 2.0]) color: #purple;
			}
			else if(preferredItem = "signed shirts")
			{
				//point hatLocation <- location + point([0.0, 0.0, 3.5]);
				draw pyramid(1.2) at: location + point([0.0, 0.0, 3.5]) color: #orange;
			}
			else if(preferredItem = "memorabillia")
			{
				//point shirtLocation <- location + point([0.0, 0.0, 1.0]);
				draw cylinder(2.01, 1.5) at: location + point([0.0, 0.0, 1.0]) color: #lime;
			}
			else if(preferredItem = "posters and artwork")
			{
				//point shirtLocation <- location + point([0.0, 0.0, 0.0]);
				draw cylinder(2.01, 1.5) at: location color: #pink;
			}
		}
	}
	
	
	reflex inAuction when: targetAuction != nil
	{
		
		if(location distance_to(targetAuction.location) > 9)
		{
			target <- targetAuction;
		}
		else
		{
			target <- nil;
		}
	}
	

	reflex beIdle when: target = nil
	{
		do wander;
	}
	
	reflex moveToTarget when: target != nil
	{
		do goto target:target.location speed: guestSpeed;
	}
	

	reflex listen_messages when: (!empty(cfps))
	{
		message requestFromInitiator <- (cfps at 0);
		// the request's format is as follows: [String, auctionType, soldItem, ...]
		if(requestFromInitiator.contents[0] = 'Start' and requestFromInitiator.contents[1] = preferredItem)
		{
			// If the guest receives a message from an auction selling its preferredItem,
			// the guest participates in that auction
			targetAuction <- requestFromInitiator.sender;

			// Send a message to the auctioner telling them the guest will participate
			
			// TODO: handle this better
			// Essentially add the guest to the interestedGuests list
//			if(self.isVIP){
//				write name + "is vip guest joins " + requestFromInitiator.sender + "'s auction for " + preferredItem;
//				targetAuction.vipGuests <+self;
//			}
//			else{
			write name + " vip joins " + requestFromInitiator.sender + "'s auction for " + preferredItem;
			targetAuction.interestedVIPGuests <+ self;
			//}
			
			
		}
		//End of auction
		else if(requestFromInitiator.contents[0] = 'Stop')
		{
//			
			write name + 'vip knows the auction is over.';
			targetAuction <- nil;
			target <- nil;
			
		}
		
		else if(requestFromInitiator.contents[0] = 'Winner')
		{
			wonAuction <- true;
			write name + ' won the auction for ' + preferredItem;
			if(preferredItem = "Memorabillia")
			{
				write "Killer Purchase Dude !!!";
			}
		}
	}
	
	
	reflex reply_messages when: (!empty(proposes))
	{
		message requestFromInitiator <- (proposes at 0);
		// TODO: maybe define message contents somewhere, rn this works
		string auctionType <- requestFromInitiator.contents[1];
		if(auctionType = "Dutch")
		{
			int offer <- int(requestFromInitiator.contents[2]);
			if (guestMaxAcceptedPrice >= offer) {
				do accept_proposal with: (message: requestFromInitiator, contents: ["I, " + name + ", vip accept your offer of " + offer]);
			}
			else
			{
				do reject_proposal (message: requestFromInitiator, contents: ["I, " + name + ", vip am afraid I cannot accept that price!"]);	
				targetAuction <- nil;
				target <- nil;
			}
		}
	}
	
}
experiment main type: gui
{
	
	output
	{
		display map type: opengl
		{
			species Guest;
			species vipGuest;
			species AuctionerMaster;
			species Auctioner;
		}
	}
}
