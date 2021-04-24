pragma solidity >= 0.5.0 < 0.6.0;

contract wager {
    function () external payable {}
    function donate() external payable {}

    mapping (address => string[]) active_challenges;
	mapping (string => uint) challenge_timeout;
	mapping (string => uint) challenge_p1_amount;
	mapping (string => uint) challenge_p2_amount;
    function wager_on_game(address opponent, address observer, uint deadline) external payable {
    	assert(msg.value > 0 ether);
    	asset(msg.sender != opponent && msg.sender != observer && opponent != observer);
    
    	// A challenge string is equal to "<p1.address> || <p2.address> || <observer.address>" where p1 is the player such that p1.address < p2.address
    	string challenge = msg.sender < opponent ? abi.encodePacked(msg.sender,opponent,observer) : abi.encodePacked(opponent,msg.sender,observer);

    	// Check that the sender is not already in this challenge
    	for (uint i=0; i<active_challenges[msg.sender].length; i++) {
    		assert( active_challenges[msg.sender][i] != challenge );
		}

		// Check that this challenge is either new or the other opponent already set the deadline and the deadlines match
		assert(challenge_timeout[challenge] == 0 || challenge_timeout[challenge] == deadline)

		// Check that if the challenge was already created that the wager_values match-+
		if ( challenge_timeout[challenge] == deadline )
		{
			if ( msg.sender < opponent )
			{
				assert( challenge_p2_amount[challenge] == msg.value );
			}
			else 
			{
				assert( challenge_p1_amount[challenge] == msg.value );
			}
		}

		// Record that msg.sender is in the challenge, save the challenge timeout value, and save the wager
		active_challenges[msg.sender].push(challenge);
		challenge_timeout[challenge] = deadline;

		if ( msg.sender < opponent )
		{
			challenge_p1_amount[challenge] = msg.value;
		}
		else 
		{
			challenge_p2_amount[challenge] = msg.value;
		}
    }

    // If the challenge hasn't timed out record who this address is claiming one
    // If an address gets 2 votes pay the winner and close the challenge

	mapping (string => address[2]) voter
	mapping (string => address[2]) votes
    function game_completed( address p1, address p2, address observer, address winner ) external payable {

    	if ( p2 < p1 )
    	{
    		address tmp = p1;
    		p1 = p2;
    		p2 = tmp;
    	}

    	// Check that the sender is in the challenge
    	assert( msg.sender == p1 || msg.sender == p2 || msg.sender == observer);

    	string challenge = p1 < p2 ? abi.encodePacked(p1,p2,observer) : abi.encodePacked(p2,p1,observer);

    	// Check that the challenge is active
    	assert( challenge_timeout[challenge] > 1 && challenge_timeout[challenge] <= block.number );

    	// Check that both players accepted the challenge
    	assert( challenge_p1_amount[challenge] == challenge_p2_amount[challenge] );

    	// Check that the sender has not already voted
    	assert( voter[challenge][0] == msg.sender && voter[challenge][1] == msg.sender );

    	// If there have been no votes, save this vote as vote 0
    	if (votes[challenge][0] == 0) { votes[challenge][0] = winner; }

    	// If this vote does not match vote 0 and there hasn't been a second vote record it  
    	else if ( votes[challenge][0] != winner && votes[challenge][1] == 0) { votes[challenge][1] = winner; }

    	// If this vote matches either vote 0 or vote 1, pay out the winner and clear the challenge;
    	else if ( votes[challenge][0] == winner || votes[challenge][1] == winner )
    	{
    		winner.transfer( challenge_p1_amount[challenge] + challenge_p2_amount[challenge] );
    		_remove_challenge( challenge, p1, p2 );
    	}

    	// If 3 votes have been cast and there is not consensus refund the challenge
    	else
    	{
    		p1.transfer( challenge_p1_amount[challenge] );
    		p2.transfer( challenge_p2_amount[challenge] );
    		_remove_challenge( challenge, p1, p2 );
    	}


    }

    function withdrawl( address opponent, address observer ) external payable {

    	address p1 = msg.sender < opponent ? msg.sender : opponent;
    	address p2 = msg.sender < opponent ? opponent : msg.sender;

    	string challenge = abi.encodePacked(p1,p2,observer);

    	// If the wager was created and the second player has not yet accepted the wager return the initial
		// or If the challenge timed out and 2 entities did not mark the game as concluding with the same winner return paid funds to both players
    	if( challenge_p1_ammount[challenge] == 0 || challenge_p2_ammount[challenge] == 0 || challenge_timeout[challenge] > block.number )
    	{
    		p1.transfer( challenge_p1_amount[challenge] );
    		p2.transfer( challenge_p2_amount[challenge] );
    		_remove_challenge( challenge, p1, p2 );
    	}
    }

    function _remove_challenge( string challenge, address p1, address p2 ) private {
    	challenge_p1_ammount[challenge] = 0;
		challenge_p2_ammount[challenge] = 0;
		challenge_timeout[challenge] = 0;

		for (uint i=0; i<active_challenges[p1].length; i++) {
			if( active_challenges[p1][i] == challenge )
			{
				active_challenges[p1][i] == active_challenges[p1.length];
				break;
			}
			active_challenges[p1].length--;
		}
		for (uint i=0; i<active_challenges[p2].length; i++) {
			if( active_challenges[p2][i] == challenge )
			{
				active_challenges[p2][i] == active_challenges[p2.length];
				break;
			}
			active_challenges[p2].length--;
		}
    }



}