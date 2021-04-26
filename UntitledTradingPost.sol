pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./UntitledCardGame.sol";

contract UntitledTradingPost {

    // Arrays of all existing cards and Players
    uint[] public forSale;

    // Check ERC721 _exists function
    function _exists(uint256 _cardId) internal view virtual returns (bool) {
        return _owners[_cardId] != address(0);
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

    // removes the indexed card from a collection
    function remove(uint[] _collection, uint _index)  returns(uint[]) {
        if (_index >= _collection.length) return;

        for (uint i = _index; i < _collection.length - 1 ; i++){
            _collection[i] = _collection[i+1];
        }
        _collection.length--;
        return _collection;
    }

    function tradeCards(address from, address to, uint256 _cardIdFrom, uint256 _cardIdTo) public {
        // Makes sure both addresses own the two cards
        require(_isOwner(_msgSender(), _cardIdFrom), "ERC721: transfer caller is not owner");
        require(_isOwner(to, _cardIdTo)), "ERC721: transfer destination is not owner");
        // Uses Transfer function from UntitledCardGame contract to send cards between players
        UntitledCardGame.transferFrom(from, to, _cardIdFrom);
        UntitledCardGame.transferFrom(to, from, _cardIdTo);
    }

    function setForTrade(address from, uint256 _cardId) public {
        require(_isOwner(_msgSender(), _cardId), "ERC721: transfer caller is not owner");
        // Appends cards to the
        forSale.push(_cardId);
    }

    // returns the index of a card in a collection
    function indexOf(uint[] _collection, uint _cardId) public returns(uint) {
        for (uint i = 0; i < _collection.length - 1 ; i++){
            if(_collection[i] == _cardId) {
                uint _index = i;
                break
            }
        }
        return _index;
    }

    //function for accepting a trade
    function acceptTrade(bool accept, uint256 _indexCard, address _trader) public {
        // Finds the index of a card on sale
        uint256 _cardId = indexOf(forSale, _indexCard);
        // Checks that the trade is accepted and the person accepting is the original card owner
        require(_isOwner(_msgSender(), forSale[_cardId]), "ERC721: transfer caller is not owner");
        require(accept, "Trade Rejected");
        // Tranfers the cards
        UntitledCardGame.transferFrom(_msgSender(), forSale[_cardId], _trader);
    }

}
