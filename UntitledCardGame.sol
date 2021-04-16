pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract UntitledCardGame is ERC721  {

    // Card Structure
    struct Card {
        uint cardId;
        string name;
        uint rarity;
        uint cost;
        uint attack;
        uint health;
        bool hasTaunt;
        bool hasCharge;
        string battleCryType;
        string[] battleCryArg;
    }
    
    // Player
    struct Player {
        address playerId;
        string name;
    }

    // Mapping from cardID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to deck
    mapping (address => uint256[]) private _collection;

    // Arrays of all existing cards and Players
    Card[] public cards;
    Player[] public players;
    // Address of the game creator
    address[3] public owners =[0x3dc046ccb798003bb6e4593fe5f9be19af675435,0x89d04466b6351a7ec9382196087cf2b8104592a0,0x154A1E9427Ed41007eadA3A49583AA9C34784962];

    // Sets game creator as the owner of the contract
    function UntitledCardGame() public {
        owner = msg.sender;
    }

    // Creates Cards
    function createCard(uint8 _cardNum, string _name, uint _rarity, uint _cost, uint _attack, uint _health, bool _hasTaunt, bool _hasCharge, string _battleCryType, string[] _battleCryArg, address _to) public {
        // Only the owner can create cards
        require(owners[0] == msg.sender || owners[1] == msg.sender || owners[2] == msg.sender);
        // Hashes card name for card ID
        uint nameHash = (uint)(keccak256(abi.encode(_name)));
        // Concatenates with which iteration of the card this is to generate a unique id
        uint _cardId = nameHash||_cardNum;
        // Add's newly generated card to array of cards in existence
        cards.push(Card(_cardId, _name, _rarity, _cost, _attack, _health, _hasTaunt, _hasCharge, _battleCryType, _battleCryType));
        _mint(_to, _cardId);
    }

    // Creates Players
    function createPlayer(string _name) public {
        // Only the owner can create players
        require(owner == msg.sender);
        // Hashes card name for card ID
        address playerId = (address)(keccak256(abi.encode(_name)));
        // Add's newly generated Player to array of Players in game
        players.push(Player(playerId, _name));
    }

    // Check ERC721 _mint function
    function _mint(address to, uint256 _cardID) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        // Token transfer hook
        _beforeTokenTransfer(address(0), to, _cardID);
        // adds to the collection of the new owner.
        _collection[to].push(_cardID);
        _owners[_cardID] = to;

        emit Transfer(address(0), to, _cardID);
    }

    // Check ERC721 _isApprovedOrOwner function
    function _isOwner(address spender, uint256 cardId) internal view virtual returns (bool) {
        // Makes sure Card Exists
        require(_exists(cardId), "ERC721: operator query for nonexistent token");
        // Sets cardOwner to be address of the actual card owner
        address cardOwner = UntitledCardGame.ownerOf(cardId);
        // Boolean of wether the function caller is the card owner.
        return (spender == cardOwner);
    }

    //  Function that returns the card collection of player (Check ERC721 balanceOf function)
    function collectionOf(address playerId) public view virtual override returns (uint256[]) {
        return _deck[playerId];
    }

    // Function that returns the owner of card (Check ERC721 ownerOf function)
    function ownerOf(uint256 cardId) public view virtual override returns (address) {
        address cardOwner = _owners[cardId];
        require(cardOwner != address(0), "ERC721: owner query for nonexistent token");
        return cardOwner;
    }

    // returns the index of a card in a collection
    function indexOf(uint[] _collection, uint _cardId) returns(uint) {
        for (uint i = 0; i < _collection.length - 1 ; i++){
            if(_collection[i] == _cardId) {
                uint _index = i;
                break
            }
        }
        return _index;
    }

    // removes the indexed card from a collection
    function remove(uint[] _collection, uint _index)  returns(uint[]) {
        if (_index >= _collection.length) return;

        for (uint i = _index; i < _collection.length - 1 ; i++){
            _collection[i] = _collection[i+1];
        }
        _collection.length--;
        return _collection;
    }

    // Transfer Token Hook
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }

    // Function that burns and sends cards.
    function _transfer(address from, address to, uint256 _cardId) internal virtual {
        require(UntitledCardGame.ownerOf(_cardId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        //  Hook that is called before any token transfer. This includes minting and burning.
        _beforeTokenTransfer(from, to, _cardId);
        // burning card from sender's collection
        _collection[from] = remove(_collection[from], indexOf(_collection[from], _cardID));
        // appending card to receiver's collection
        _collection[to].push(_cardID);
        // setting receiver as card owner
        _owners[_cardId] = to;
        // Emits transfer event
        emit Transfer(from, to, _cardID);
    }

    // Function that transfers ownership of card from players (Check ERC721 transferFrom function)
    function transferFrom(address from, address to, uint256 _cardId) public virtual override {
        require(_isOwner(_msgSender(), _cardId), "ERC721: transfer caller is not owner");
        // transfer call
        _transfer(from, to, _cardId);
    }



}
