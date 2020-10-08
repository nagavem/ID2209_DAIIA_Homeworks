/***
* Name: MultipleAuction
* Author: ayushi and Naga
* Description: Challenge 2 : Multiple Auctions taking place namely- Dutch,English and Sealed
***/

model MultipleAuction


global 
{
	/*
	 * Guest configs
	 */
	int guestNumber <- rnd(20)+20;
	//int guestNumber <- 1;
	float guestSpeed <- 0.5;
	
	/*
	 * Auction configs
	 */
	point AuctionMasterLocation <- {-10,50};
	list<string> itemsAvailable <- ["instruments","signed shirts","memorabillia"];
	
	// Time when auctioneers are created
	int auctionCreationMin <- 0;
	int auctionCreationMax <- 50;
	
	// Guest accepted price range min and max
	int guestAcceptedPriceMin <- 100;
	int guestAcceptedPriceMax <- 1500;
	
	// English auction configs
	// bid raise min and max
	int engAuctionMinRaise <- 30;
	int engAuctionMaxRaise <- 60;
	
	// The initial price of the item to sell
	int engAuctionMinPrice <- 0;
	int engAuctionMaxPrice <-1500;
	
	// Dutch auction configs
	// bid decrease min and max 
	int dutchAuctionDecreaseMin <- 5;
	int dutchAuctionDecreaseMax <- 15;
	// The initial price of the item to sell, set above the max price so that no guest immediately wins
	int auctionerDutchPriceMin <- 1504;
	int auctionerDutchPriceMax <-1600;
	// Minimum price of the item, if the bids go below this the auction fails
	int auctionerMinimumValueMin <- 90;
	int auctionerMinimumValueMax <- 300;
	
	
	list<string> auctionTypes <- ["Dutch", "English", "Sealed"];

	
	
	init
	{
		/* Create guestNumber (defined above) amount of Guests */
		create Guest number: guestNumber
		{
			// Each guest prefers a random item
			preferredItem <- itemsAvailable[rnd(length(itemsAvailable) - 1)];
		}
		
		/*
		 * Number of auctioners is defined above 
		 */
		create AuctionMaster
		{
			
		}
	}
	
}


/*
 * Each guest has a random preferred price for merch
 * They will reject offers until their preferred price is reached,
 * upon which moment they accept and buy the merch
 */
species Guest skills:[moving, fipa]
{		
	bool auctionWinner <- false;
	
	// Default color of guests
	rgb color <- #red;
	
	// This is the price at which the guest will buy merch, set in the configs above
	int guestMaxAcceptedPrice <- rnd(guestAcceptedPriceMin,guestAcceptedPriceMax);
	
	// Which auction is guest participating in
	Auctioner targetAuction;
	Auctioner target;
	
	// each guest prefers a single piece of merchandice
	string preferredItem;
	
	aspect default
	{
		draw sphere(2) at: location color: color;

		if (auctionWinner = true)
		{
			if(preferredItem = "instruments")
			{
				//point backPackLocation <- location + point([2.1, 0.0, 2.0]);
				//backPackLocation <- backPackLocation.x + 1; 
				draw cube(1.2) at: location + point([2.1, 0.0, 2.0]) color: #purple;
			}
			else if(preferredItem = "Signed Shirts")
			{
				//point hatLocation <- location + point([0.0, 0.0, 3.5]);
				draw pyramid(1.2) at: location + point([0.0, 0.0, 3.5]) color: #orange;
			}
			else if(preferredItem = "Memorabillia")
			{
				//point shirtLocation <- location + point([0.0, 0.0, 1.0]);
				draw cylinder(2.01, 1.5) at: location + point([0.0, 0.0, 1.0]) color: #lime;
			}
			else if(preferredItem = "Posters and Artwork")
			{
				//point shirtLocation <- location + point([0.0, 0.0, 0.0]);
				draw cylinder(2.01, 1.5) at: location color: #pink;
			}
		}
	}
	
	/*
	 * When the guest has a targetAuction, it is considered participating in that auction
	 * A target auction is an auction selling the types of items the guest is interested in
	 */
	reflex inAuction when: targetAuction != nil and !dead(targetAuction)
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
	

	/* 
	 * Agent's default behavior at the festival
	 */
	reflex beIdle when: target = nil
	{
		do wander;
	}
	
	/* 
	 * When agent has target, move towards target
	 */
	reflex moveToTarget when: target != nil
	{
		do goto target:target.location speed: guestSpeed;
	}
	
	reflex listen_messages when: (!empty(cfps))
	{
		message initiateRequest <- (cfps at 0);
		// the request's format is as follows: [String, auctionType, soldItem, ...]
		if(initiateRequest.contents[0] = 'Start' and initiateRequest.contents[1] = preferredItem)
		{
			// If the guest receives a message from an auction selling its preferredItem,
			// the guest participates in that auction
			targetAuction <- initiateRequest.sender;

			// Send a message to the auctioner telling them the guest will participate
			write name + " joins " + initiateRequest.sender + "'s auction for " + preferredItem;
			// TODO: handle this better
			// Essentially add the guest to the interestedGuests list
			targetAuction.interestedGuests <+ self;
		}
		//End of auction
		else if(initiateRequest.contents[0] = 'Stop')
		{

			write name + ' knows the auction is over.';
			targetAuction <- nil;
			target <- nil;
			
		}
		//Time to send bid for sealed bidding
		else if(initiateRequest.contents[0] = 'Bid For Sealed')
		{
			do start_conversation (to: initiateRequest.sender, protocol: 'fipa-propose', performative: 'propose', contents: ['This is my offer', guestMaxAcceptedPrice]);
			targetAuction <- nil;
			target <- nil;
		}
		//next round for english bidding
		else if(initiateRequest.contents[0] = 'Bid for English')
		{
			int currentBid <- int(initiateRequest.contents[1]);
			//can bid more
			if (guestMaxAcceptedPrice > currentBid) 
			{
				int newBid <- currentBid + rnd(engAuctionMinRaise, engAuctionMaxRaise);
				if(newBid > guestMaxAcceptedPrice)
				{
					newBid <- guestMaxAcceptedPrice;
				}
				//write name + ' sending propose ' + newBid;
				do start_conversation (to: initiateRequest.sender, protocol: 'fipa-propose', performative: 'propose', contents: ['This is my offer', newBid]);
			}
			//can't bid more
			else
			{
				write name + ": Price is too high I would like to withdraw ";
				do reject_proposal (message: initiateRequest, contents: [" Price is too high I would like to withdraw"]);
				targetAuction <- nil;
				target <- nil;
			}
		}
		else if(initiateRequest.contents[0] = 'Winner')
		{
			auctionWinner <- true;
			write name + ' won the auction for ' + preferredItem;
			if(preferredItem = "Memorabillia")
			{
				write "Killer Purchase Dude!!!";
			}
		}
	}
	
	/*
	 * In Dutch auction, the auctioner proposes and the participant can accept or reject it, based on the price it would pay for it.
	 */
	reflex reply_messages when: (!empty(proposes))
	{
		message initiateRequest <- (proposes at 0);
		// TODO: maybe define message contents somewhere, rn this works
		string auctionType <- initiateRequest.contents[1];
		if(auctionType = "Dutch")
		{
			int offer <- int(initiateRequest.contents[2]);
			if (guestMaxAcceptedPrice >= offer) {
				do accept_proposal with: (message: initiateRequest, contents: ["I, " + name + ", accept your offer of " + offer]);
			}
			else
			{
				do reject_proposal (message: initiateRequest, contents: ["I, " + name + ", would not like to bid for this value!"]);	
				targetAuction <- nil;
				target <- nil;
			}
		}
	}
	
}// Guest end


/*
 * The AuctionMaster creates auctioners
 */
species AuctionMaster skills:[fipa]
{
	bool auctionersCreated <- false;
	list<Auctioner> auctioners <- [];
///	/*
//	 * This creates the auctioners within the set time limits from the beginning.
//	 * auctionCreationMin and auctionCreationMax set at the top
//	 */

	reflex createAuctioners when: !auctionersCreated and time rnd(auctionCreationMin, auctionCreationMax)
	{
		string genesisString <- name + " creating auctions: ";
		
		loop i from: 0 to: length(itemsAvailable)-1
		{
			create Auctioner
			{	
				location <- {rnd(100),rnd(100)};
				soldItem <- itemsAvailable[i];
				auctionType <- auctionTypes[i];
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
	int DeadAuctioners <- 0;
	
	// price of item to sell
	int auctionerDutchPrice <- rnd(auctionerDutchPriceMin, auctionerDutchPriceMax);
	int auctionerEngPrice <- rnd(engAuctionMinPrice, engAuctionMaxPrice);
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
		if(auctionType= "English"){
			myColor<- #gold;
		}
		else if(auctionType= "Sealed"){
			myColor<- #green;
		}
		else{
			myColor<- #blue;
		}
		draw circle(mySize) color: myColor;
		
	}
	
	
	
	
	/*
	 * Send out the first auction message to all guest after a random amount of time
	 * Interested guests will answer and be added to interestedGuests
	 * The auction will start once the guests have gathered
	 * 
	 * startAnnounced is here to ensure we don't spam the announcement message
	 */
	reflex sendStartAuction when: !auctionRunning and time >= 90 and targetLocation = nil and !startAnnounced
	{
		write name + " starting " + auctionType + " soon";
		do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ['Start', soldItem]);
		startAnnounced <- true;
		
	}
	
	/*
	 * sets auctionStarted to true when interestedGuests are within a distance of 13 to the auctioner.
	 */
	reflex guestsAreAround when: !auctionRunning and !empty(interestedGuests) and (interestedGuests max_of (location distance_to(each.location))) <= 13
	{
		write name + " guestsAreAround";
		auctionRunning <- true;
	}

	/*
	 * Dutch auction: auctioner sends a propose message and guests can reply with accept or reject messages. The auction ends with the first accept.
	 */
	reflex receiveAcceptMessages when: auctionRunning and !empty(accept_proposals)
	{
		if(auctionType = "Dutch")
		{
			write name + ' receives accept messages';
			
			loop a over: accept_proposals {
				write name + ' got accepted by ' + a.sender + ': ' + a.contents;
				do start_conversation (to: a.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ['Winner']);
			}
			targetLocation <- AuctionMasterLocation;
			auctionRunning <- false;
			//end of auction
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop']);
			interestedGuests <- [];
			DeadAuctioners<- DeadAuctioners + 1;
			do die;
		}
	}

	/*
	 * In sealed and english auction, the participants send proposes to the auctioner. The auctioner gets them here.
	 * In Sealed, the highest bid wins right away.
	 * In English, this just sets the current highest bid and the auction goes on.
	 */ 
	reflex getProposes when: (!empty(proposes))
	{
		if(auctionType = "Sealed")
		{
			targetLocation <- AuctionMasterLocation;
			auctionRunning <- false;

			loop p over: proposes {
				write name + ' got an offer from ' + p.sender + ' of ' + p.contents[1] + ' kronas.';
				if(currentBid < int(p.contents[1]))
				{
					currentBid <- int(p.contents[1]);
					currentWinner <- p.sender;
					winner <- p;
				}
			}
			do start_conversation (to: winner.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ['Winner']);
			write name + ' bid ended. Sold to ' + currentWinner + ' for: ' + currentBid;
			do accept_proposal with: (message: winner, contents: ['Item is yours']);
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ["Stop"]);
			
			interestedGuests <- [];
			DeadAuctioners<- DeadAuctioners + 1;
			do die;
		}
		else if(auctionType = "English")
		{
			loop p over: proposes {
				write name + ' got an offer from ' + p.sender + ' of ' + p.contents[1] + ' kronas.';
				if(currentBid < int(p.contents[1]))
				{
					currentBid <- int(p.contents[1]);
					currentWinner <- p.sender;
					winner <- p;
				}
			}
			
		}
	}
	/*
	 * Reject messages are used in Dutch and English auctions.
	 * Dutch: Starting from high bid and goes on as long as everybody rejects the proposal. Here, we decrese the price of the item.
	 * If the price goes below the minimum expected price, the auction ends.
	 * English: Reject messages mean that participants don't wish to bid more and are out of the auction.
	 * If everyone is out or just one person left, the auction ends.
	 */
	reflex receiveRejectMessages when: auctionRunning and !empty(reject_proposals)
	{
		if(auctionType = "Dutch")
		{
			write name + ' receives reject messages';
			
			auctionerDutchPrice <- auctionerDutchPrice - rnd(dutchAuctionDecreaseMin, dutchAuctionDecreaseMax);
			if(auctionerDutchPrice < auctionerMinimumValue)
			{
				targetLocation <- AuctionMasterLocation;
				auctionRunning <- false;

				write name + ' price went below minimum value (' + auctionerMinimumValue + '). It is not feasible to continue!';
				do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Stop']);
				do die;
				DeadAuctioners<- DeadAuctioners + 1;				
				interestedGuests <- [];
			}
		}
		else if(auctionType = "English")
		{	
			loop r over: reject_proposals 
			{
				interestedGuests >- r.sender;
			}
			if(length(interestedGuests) < 2)
			{
				targetLocation <- AuctionMasterLocation;
				auctionRunning <- false;

				if(currentBid < auctionerMinimumValue)
				{
					write name + ' bid ended. No more auctions !';
				}
				else
				{
					write 'Bid ended. Winner is: ' + currentWinner + ' with a bid of ' + currentBid;	
					do start_conversation (to: winner.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ['Winner']);
				}
				if(!empty(interestedGuests))
				{
					do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ["Stop"]);
				}
				do die;
				interestedGuests <- [];
				DeadAuctioners<- DeadAuctioners + 1;
			}
		}
	}
	/*
	 * Dutch: every iteration, it sends the decreased price of the item to the participants which they can accept of reject
	 * English: every iteration, tells guests about the current highest bid that they need to outbid
	 * Sealed: Start of the auction which is only one iteration
	 */
	reflex sendAuctionInfo when: auctionRunning and time >= 50 and !empty(interestedGuests){
		if(auctionType = "Dutch")
		{
			write name + ' sends the offer of ' + auctionerDutchPrice +' kronas to participants';
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'propose', contents: ['Buy my merch', auctionType, auctionerDutchPrice]);
		}
		else if(auctionType = "English")
		{
			write 'Auctioner ' + name + ': current bid is: ' + currentBid + '. Offer more or miss your chance!';
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ["Bid for English", currentBid]);
		}
		else if(auctionType = "Sealed")
		{
			write name + ' time to offer your money!!';
			do start_conversation (to: interestedGuests, protocol: 'fipa-propose', performative: 'cfp', contents: ['Bid For Sealed']);
		}
	}
	
	reflex CheackDead when: DeadAuctioners>= 3 {
		ask AuctionMaster{
			self.auctionersCreated<- false;
			write " #################### all dead";
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
			species AuctionMaster;
			species Auctioner;
		}
	}
}
