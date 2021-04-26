pragma solidity >= 0.5.0 < 0.6.0;

contract Wager {
    function () external payable {}
    function donate() external payable {}

    mapping (address => string[]) active_challenges;
    mapping (string => uint) challenge_timeout;
    mapping (string => uint) challenge_p1_amount;
    mapping (string => uint) challenge_p2_amount;
    function wager_on_game(address payable opponent, address observer, uint deadline) external payable {
        assert(msg.value > 0 ether);
        assert(msg.sender != opponent && msg.sender != observer && opponent != observer);
    
        // A challenge string is equal to "<p1.address> || <p2.address> || <observer.address>" where p1 is the player such that p1.address < p2.address
        string memory challenge = msg.sender < opponent ? string(abi.encodePacked(msg.sender,opponent,observer)) : string(abi.encodePacked(opponent,msg.sender,observer));

        // Check that the sender is not already in this challenge
        for (uint i=0; i<active_challenges[msg.sender].length; i++) {
            assert( keccak256(abi.encode(active_challenges[msg.sender][i])) != keccak256(abi.encode(challenge)) );
        }

        // Check that this challenge is either new or the other opponent already set the deadline and the deadlines match
        assert(challenge_timeout[challenge] == 0 || challenge_timeout[challenge] == deadline);

        // Check that if the challenge was already created that the wager_values match
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

    mapping (string => address[]) voter;
    mapping (string => address[]) votes;
    function game_completed( address payable p1, address payable p2, address observer, address payable winner ) external payable {

        if ( p2 < p1 )
        {
            address payable tmp = p1;
            p1 = p2;
            p2 = tmp;
        }

        // Check that the sender is in the challenge
        assert( msg.sender == p1 || msg.sender == p2 || msg.sender == observer);

        string memory challenge = p1 < p2 ? string(abi.encodePacked(p1,p2,observer)) : string(abi.encodePacked(p2,p1,observer));

        // Check that the challenge is active
        assert( block.number < challenge_timeout[challenge]  );

        // Check that both players accepted the challenge
        assert( challenge_p1_amount[challenge] == challenge_p2_amount[challenge] );
        
        // If there have been no votes or there was 1 vote but they don't match, save this vote
        if (votes[challenge].length == 0 || ( votes[challenge].length == 1 && voter[challenge][0] != msg.sender && votes[challenge][0] != winner)) { 
		voter[challenge].push(msg.sender); 
        	votes[challenge].push(winner); 
        }
        // If this vote does match vote 0 or vote 1
        else if ( voter[challenge][0] != msg.sender && ( votes[challenge][0] == winner || (voter[challenge][1] != msg.sender && votes[challenge][1] == winner) ))
        {
        	winner.transfer( challenge_p1_amount[challenge] + challenge_p2_amount[challenge] );
        	_remove_wager( challenge, p1, p2 );
        }

        // If 3 unique votes have been cast and there is not consensus refund the challenge
        else if ( voter[challenge][0] != msg.sender && voter[challenge][1] != msg.sender )
        {
            p1.transfer( challenge_p1_amount[challenge] );
            p2.transfer( challenge_p2_amount[challenge] );
            _remove_wager( challenge, p1, p2 );
        }


    }

    function withdrawl( address payable opponent, address observer ) external payable {

        address payable p1 = msg.sender < opponent ? msg.sender : opponent;
        address payable p2 = msg.sender < opponent ? opponent : msg.sender;

        string memory challenge = string(abi.encodePacked(p1,p2,observer));

        // If the wager was created and the second player has not yet accepted the wager return the initial
        // or If the challenge timed out and 2 entities did not mark the game as concluding with the same winner return paid funds to both players
        if( challenge_p1_amount[challenge] == 0 || challenge_p2_amount[challenge] == 0 || challenge_timeout[challenge] <= block.number )
        {
            p1.transfer( challenge_p1_amount[challenge] );
            p2.transfer( challenge_p2_amount[challenge] );
            _remove_wager( challenge, p1, p2 );
        }
    }

    function _remove_wager(string memory challenge, address p1, address p2 ) private {
        challenge_p1_amount[challenge] = 0;
        challenge_p2_amount[challenge] = 0;
        challenge_timeout[challenge] = 0;
        voter[challenge].length = 0;
        votes[challenge].length = 0;
                
        bytes32 challenge_hash = keccak256(abi.encode(challenge));

        for (uint i=0; i<active_challenges[p1].length; i++) {
            if( keccak256(abi.encode(active_challenges[p1][i])) == challenge_hash )
            {
                keccak256(abi.encode(active_challenges[p1][i])) == keccak256(abi.encode(active_challenges[p1][active_challenges[p2].length]));
                break;
            }
            active_challenges[p1].length--;
        }
        for (uint i=0; i<active_challenges[p2].length; i++) {
            if( keccak256(abi.encode(active_challenges[p2][i])) == challenge_hash )
            {
                keccak256(abi.encode(active_challenges[p2][i])) == keccak256(abi.encode(active_challenges[p2][active_challenges[p2].length]));
                break;
            }
            active_challenges[p2].length--;
        }
    }



}
