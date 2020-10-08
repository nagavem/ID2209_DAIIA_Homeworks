/***
* Name: DutchAuction
* Author: Naga and Ayushi
* Description: Simple, single Dutch Auction being simulated
***/

model NewModel
global 
{
	int guestNumber <- rnd(20)+20;
	
	float guestSpeed <- 0.5;	
	
	 
	point auctionMasterLocation <- {-10,50};
	list<string> itemsAvailable <- ["Instruments"];
	
	// Time when auctioneers are created
	int auctionCreationMin <- 0;
	int auctionCreationMax <- 50;
	
	// Guest accepted price range min and max
	int guestAcceptedPriceMin <- 100;
	int guestAcceptedPriceMax <- 1500;
	
	int dutchAuctionDecrementMin <- 5;
	int dutchAuctionDecrementMax <- 15;
	
	
	// The initial price of the item to sell, set above the max price so that no guest immediately wins
	int auctionerDutchPriceMin <- 1504;
	int auctionerDutchPriceMax <-1600;
	// Minimum price of the item, if the bids go below this the auction fails
	int auctionerMinimumValueMin <- 90;
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
		
		/*This species is used to create the auctioneers */
		create AuctionCreator
		{
			
		}
	}
	
}

species Guest skills:[moving, fipa]
{
	bool wonAuction <- false;
	
	// Default color of guests
	rgb color <- #red;
	
	// This is the price at which the guest will buy merch, set in the configs above
	int MaxSellablePrice <- rnd(guestAcceptedPriceMin,guestAcceptedPriceMax);
	
	// Which auction is guest participating in
	Auctioner targetAuction;
	Auctioner target;
	
	// each guest prefers a single piece of merchandice
	string preferredItem;
	
	aspect default
	{
		draw sphere(2) at: location color: color;

		if (wonAuction = true)
		{
			if(preferredItem = "Instruments")
			{
			 
				color<- #purple;
				
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
	
    reflex listen_fipa_messages when: (!empty(cfps))
	{
		message initiateRequest <- (cfps at 0);
		
		if(initiateRequest.contents[0] = 'Start' and initiateRequest.contents[1] = preferredItem)
		{
			
			targetAuction <- initiateRequest.sender;

			// Send a message to the auctioner telling them the guest will participate
			write name + " joins " + initiateRequest.sender + "'s auction for " + preferredItem;
		
			targetAuction.interestedGuests <+ self;
		}
		//End of auction
		else if(initiateRequest.contents[0] = 'Stop')
		{
			write name + ' knows the auction is over.';
			targetAuction <- nil;
			target <- nil;
			
		}
		
		else if(initiateRequest.contents[0] = 'Winner')
		{
			wonAuction <- true;
			write name + ' won the auction for ' + preferredItem;
			if(preferredItem = "Posters and artwork")
			{
				write "Congratss !!!";
			}
		}
	}
	
	reflex reply_fipa_messages when: (!empty(proposes))
	{
		message initiateRequest <- (proposes at 0);
		
		string auctionType <- initiateRequest.contents[1];
		if(auctionType = "Dutch")
		{
			int offer <- int(initiateRequest.contents[2]);
			if (MaxSellablePrice >= offer) {
				do accept_proposal with: (message: initiateRequest, contents: ["I, " + name + ", accept your offer of " + offer ]);
			}
			else
			{
				do reject_proposal (message: initiateRequest, contents: ["I, " + name + ", am afraid I do not wish to participate!"]);	
				targetAuction <- nil;
				target <- nil;
			}
		}
	}
	
}// Guest end

species AuctionCreator skills:[fipa]
{
	bool auctionersCreated <- false;
	list<Auctioner> auctioners <- [];

	reflex create_Auctioners when: !auctionersCreated and time rnd(auctionCreationMin, auctionCreationMax)
	{
		string itemsForAuction <- name + " creating auctions: ";
		
		loop i from: 0 to: length(itemsAvailable)-1
		{
			create Auctioner
			{	
				location <- {rnd(100),rnd(100)};
				soldItem <- itemsAvailable[i];
				itemsForAuction <- itemsForAuction + name + " with " + itemsAvailable[i] + " ";
				myself.auctioners <+ self;
			}
		}
		write itemsForAuction;
		auctionersCreated <- true;
	}	
}


species Auctioner skills:[fipa, moving]
{
	// Auction's initial size and color, location used in the beginning
	int mySize <- 10;
	rgb myColor <- #blueviolet;
	point targetLocation <- nil;
	bool win<- false;
	
	// price of item to sell
	int auctionerDutchPrice <- rnd(auctionerDutchPriceMin, auctionerDutchPriceMax);
	// minimum price of item to sell. if max bid is lower than this, bid is unsuccessful
	int auctionerMinimumValue <- rnd(auctionerMinimumValueMin, auctionerMinimumValueMax);
	
	// vars related to start and end of auction
	bool auctionRunning <- false;
	bool startAnnounced <- false;
	
	string auctionType <- auctionTypes[rnd(length(auctionTypes) - 1)];
	int currentBid <- 0;
	string currentWinner <- nil;
	message winner <- nil;

	// The kind of an item the merchant is selling
	string soldItem <- "";
	// The guests participating in the auction
	list<Guest> interestedGuests;

	aspect
	{
		
		draw circle(mySize) color: myColor;
		
	}
	
	

	reflex send_Start_Auction when: !auctionRunning and time >= 90 and targetLocation = nil and !startAnnounced
	{
		write name + " starting " + auctionType + " soon";
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ['Start', soldItem]);
		startAnnounced <- true;
		
	}
	
	
	reflex guests_Are_Around when: !auctionRunning and !empty(interestedGuests) and (interestedGuests max_of (location distance_to(each.location))) <= 13
	{
		write name + " guestsAreAround";
		auctionRunning <- true;
	}

	
	reflex receive_Accept_Messages when: auctionRunning and !empty(accept_proposals)
	{
		if(auctionType = "Dutch")
		{
			write name + ' receives accept messages';
			
			loop a over: accept_proposals {
				write name + ' got accepted by ' + a.sender + ': ' + a.contents;
				if(win = false){
				do start_conversation (to: a.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ['Winner']);
				win <- true;
				}
				
			}
			
			auctionRunning <- false;
			//end of auction
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop']);
			interestedGuests <- [];
			do die;
		}
	}


	reflex receive_Reject_Messages when: auctionRunning and !empty(reject_proposals)
	{
		if(auctionType = "Dutch")
		{
			write name + ' receives reject messages';
			
			auctionerDutchPrice <- auctionerDutchPrice - rnd(dutchAuctionDecrementMin, dutchAuctionDecrementMax);
			if(auctionerDutchPrice < auctionerMinimumValue)
			{
				targetLocation <- auctionMasterLocation;
				auctionRunning <- false;

				write name + ' price went below minimum value (' + auctionerMinimumValue + '). No more auction for thrifty guests!';
				do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop']);
				interestedGuests <- [];
				do die;
			}
		}

	}
	
	reflex sendAuctionInfo when: auctionRunning and time >= 50 and !empty(interestedGuests){
		if(auctionType = "Dutch")
		{
			write name + ' sends the offer of ' + auctionerDutchPrice +' krona to participants';
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'propose', contents: ['Buy my merch, peasant', auctionType, auctionerDutchPrice]);
		}
	}	
}// Auctioner


experiment main type: gui
{
	
	output
	{
		display map type: opengl
		{
			species Guest;
			species AuctionCreator;
			species Auctioner;
		}
	}
}
	
