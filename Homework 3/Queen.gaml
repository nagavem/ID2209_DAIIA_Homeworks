/***
* Name: queen
* Author: ayushi and Naga
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model queen

/* Insert your model definition here */
global {
    int neighbors <- 8;
    int queens <- 12;
    
    init{
        create Queen number: queens;
    }
    
    list<chessBoardCell> allCells;
    list<Queen> allQueens;
    
    bool isCalculating <- false;
    
}

species Queen{
    chessBoardCell myCell <- one_of (chessBoardCell);
    list<list<int>> occupancyGrid;
    
    init {
        //Assign a free cell
        loop cell over: myCell.neighbours{
            if cell.queen = nil{
                myCell <- cell;
                break;        
            }
        }
        location <- myCell.location;
        myCell.queen <- self;
        
        add self to: allQueens;
        
        do refreshOccupancyGrid;
    }
    
    action refreshOccupancyGrid{
        self.occupancyGrid <- [];
        loop m from:0 to: queens-1{
            list<int> mList;
            loop n from:0 to: queens-1{
                add 0 to: mList;    
            }
            add mList to: occupancyGrid;
        }
    }
    
    action calculateOccupancyGrid{
        do refreshOccupancyGrid;
        
        // Identify all occupied allCells
        loop cell over: allCells{
            if cell.queen != nil and cell.queen != self{
                self.occupancyGrid[cell.grid_x][cell.grid_y] <- 1000;
            }
        }
        
        // Evaluate free allCells
            loop cell over: allCells{
                int m <- cell.grid_x;
                int n <- cell.grid_y;
                if self.occupancyGrid[int(m)][int(n)] = 1000{
                    loop i from: 1 to:queens{
                        
                        // Up
                        int mi <- int(m) + i;
                        if mi < queens{
                            self.occupancyGrid[mi][n] <- self.occupancyGrid[mi][n] + 1;
                        }
                        
                        //Down
                        int n_mi <- int(m) - i;
                        if n_mi > -1{
                            self.occupancyGrid[n_mi][n] <- self.occupancyGrid[n_mi][n] + 1;
                        }
                        
                        // Right
                        int ni <- int(n) + i;
                        if ni < queens{
                            self.occupancyGrid[m][ni] <- self.occupancyGrid[m][ni] + 1;
                        }
                        
                        //Left
                        int n_ni <- int(n) - i;
                        if n_ni > -1{
                            self.occupancyGrid[m][n_ni] <- self.occupancyGrid[m][n_ni] + 1;
                        }
                        
                        //top right diagonal
                        if mi < queens and ni < queens{
                            self.occupancyGrid[mi][ni] <- self.occupancyGrid[mi][ni] + 1;
                        }
                        
                        //bottom right diagonal
                        if n_mi > -1 and ni < queens{
                            self.occupancyGrid[n_mi][ni] <- self.occupancyGrid[n_mi][ni] + 1;
                        }
                        
                        //top left diagonal
                        if mi < queens and n_ni > -1{
                            self.occupancyGrid[mi][n_ni] <- self.occupancyGrid[mi][n_ni] + 1;
                        }
                        
                        //bottom left diagonal
                        if n_mi > -1 and n_ni > -1{
                            self.occupancyGrid[n_mi][n_ni] <- self.occupancyGrid[n_mi][n_ni] + 1;
                        }
                    }
                }
            }
    }
    
    list<point> availableallCells(int val) {
        list<point> Checks;
        loop cell over: allCells{
            int m <- cell.grid_x;
            int n <- cell.grid_y;
            if self.occupancyGrid[int(m)][int(n)] = val and !(m = myCell.grid_x and n = myCell.grid_y){
            	add {int(m),int(n)} to: Checks;
            }
        }
        return Checks;
    }
    
    
    Queen findQueenInSightbyLocation(int x){
    	list<Queen> queensInSight;
    	
    	loop cell over: allCells{
            int m <- cell.grid_x;
            int n <- cell.grid_y;
            
            if self.occupancyGrid[m][n] > 999{
            	if m = self.myCell.grid_x {
            		add cell.queen to: queensInSight;
            	}
            	else if n = self.myCell.grid_y {
            		add cell.queen to: queensInSight;
            	}
            	else{
            		int diff_x <- abs(m - self.myCell.grid_x);
            		int diff_y <- abs(n - self.myCell.grid_y);
            		if diff_x = diff_y{
            			add cell.queen to: queensInSight;
            		}
            	}
            }
        }
    	
    	if length(queensInSight) > 0{
    		Queen sight <- queensInSight[rnd(0, length(queensInSight)-1)];
    		return sight;	
    	} else{
    		return nil;
    	}
    }
    
    action needToMove{
    	do calculateOccupancyGrid();
	    if self.occupancyGrid[myCell.grid_x][myCell.grid_y] != 0{
	    	list<point> possibleChecks <- availableallCells(0);
	    	if length(possibleChecks) > 0 {
	    		point possiblePoint <- possibleChecks[rnd(0,length(possibleChecks)-1)];
	    		loop c over: allCells {
	    			if c.grid_x = possiblePoint.x and c.grid_y = possiblePoint.y and c.queen = nil{
	    				myCell.queen <- nil;
	    				myCell <- c;
	    				location <- c.location;
	    				myCell.queen <- self;
	    				
	    				write name;
	    				write "Options: " + possibleChecks;
	    				write "Moved to: " + c.grid_x + ", " + c.grid_y;
	    				write "Grid: " + self.occupancyGrid;
	    				
	    				break;
	    			}
	    		}
	    	}
	    	else{
	    		write "I cannot move from: " + self.myCell.grid_x + ", " + self.myCell.grid_y;
	    		// Communicate with others for moving
	    		Queen sight <- findQueenInSightbyLocation(0);
	    		if sight != nil{
	    			chessBoardCell sightCell;
	    			ask sight{
	    				write "I am at : " + myself.myCell.grid_x + ", " + myself.myCell.grid_y + " Trying to move to: " + self.myCell.grid_x + ", " + self.myCell.grid_y;
	    				sightCell <- self.myCell;
	    			}
	    			chessBoardCell target;
	    			float distance <- 1000.0;
	    			loop s over:sightCell.neighbours{
	    				float dist <- myCell.location distance_to s.location;
	    				if dist < distance and dist!=0 and s.queen = nil{
	    					distance <- dist;
	    					target <- s;
	    				}
	    			}
	    			write "New Location is follows: " + target.grid_x + ", " + target.grid_y;
	    			myCell.queen <- nil;
	    			myCell <- target;
	    			location <- target.location;
	    			myCell.queen <- self;
	    		}
	    	}
	    }
	}
    
    //REFLEXES
    reflex amIsafe when: !isCalculating{
    	isCalculating <- true;
    	do needToMove;
    	isCalculating <- false;
    }
    
    
    aspect base {
        draw circle(1.0) color: #black ;
    }
}

grid chessBoardCell width: queens height: queens neighbors: neighbors {
    list<chessBoardCell> neighbours  <- (self neighbors_at 2);
    Queen queen <- nil;
    
    init{
        add self to: allCells;
    }
}

experiment ChessBoard type: gui {
    output {
        display main_display {
            grid chessBoardCell lines: #black ;
            species Queen aspect: base ;
        }
    }
}

