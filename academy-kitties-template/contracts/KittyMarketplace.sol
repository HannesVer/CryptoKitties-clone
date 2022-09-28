// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Kittycontract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * Market place to trade kitties (should **in theory** be used for any ERC721 token)
 * It needs an existing Kitty contract to interact with
 * Note: it does not inherit from the kitty contracts
 * Note: The contract needs to be an operator for everyone who is selling through this contract.
 */

interface KittyMarketPlace is Ownable {
    Kittycontract private _kittyContract;

    struct Offer {
        address payable seller;
        uint256 price;
        uint256 index;
        uint256 tokenId;
        bool active;
    }

    Offer[] offers;
    mapping(uint256 => Offer) tokenIdToOffer;
    mapping(uint256 => uint256) tokenIdToOfferId;
    mapping(uint256 => address) tokenOwner;
    mapping(uint256 => address) public tokenApproved;

    event MarketTransaction(string TxType, address owner, uint256 tokenId);

    /**
     * Set the current KittyContract address and initialize the instance of Kittycontract.
     * Requirement: Only the contract owner can call.
     */
    function setKittyContract(address _kittyContractAddress) public onlyOwner {
        _kittycontract = Kittycontract(_kittyContractAddress);
    }

    constructor(address _kittyContractAddress) public {
        setKittyContract(_kittyContractAddress);
    }

    /**
     * Get the details about a offer for _tokenId. Throws an error if there is no active offer for _tokenId.
     */
    function getOffer(uint256 _tokenId)
        public
        view
        returns (
            address seller,
            uint256 price,
            uint256 index,
            uint256 tokenId,
            bool active
        )
    {
        Offer storage offer = offers[_tokenId];
        require(offer.active = true, "this token is not for sale");
        seller = address(offer.seller);
        price = uint256(offer.price);
        index = uint256(offer.index);
        tokenId = uint256(offer.tokenId);
        active = bool(offer.active);
    }

    /**
     * Get all tokenId's that are currently for sale. Returns an empty arror if none exist.
     */
    function getAllTokenOnSale()
        external
        view
        returns (uint256[] memory listOfOffers)
    {
        uint256 totalOffers = offers.length;

        if (totalOffers == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory offerlist = new uint256[](totalOffers);

            uint256 offerId;

            for (offerId = 0; offerId < totalOffers; offerId++) {
                if (offers[offerId].price != 0) {
                    offerlist[offerId] = offers[offerId].tokenId;
                }
            }
            return offerlist;
        }
    }

    function _ownsKitty(address _address, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return (_kittyContract.ownerOf(_tokenId) == _address);
    }

    /**
     * Creates a new offer for _tokenId for the price _price.
     * Emits the MarketTransaction event with txType "Create offer"
     * Requirement: Only the owner of _tokenId can create an offer.
     * Requirement: There can only be one active offer for a token at a time.
     * Requirement: Marketplace contract (this) needs to be an approved operator when the offer is created.
     */
    function setOffer(uint256 _price, uint256 _tokenId) external {
        require(_ownsKitty(msg.sender, _tokenId), "you do not own this token");
        require(
            offers[_tokenId].active == false,
            "this token is already on offer"
        );
        require(
            _kittyContract.isApprovedForAll(msg.sender, address(this)),
            "contract needs to be approved for this token"
        );
        _createoffer(_price, _tokenId);
    }

    /*
     * Removes an existing offer.
     * Emits the MarketTransaction event with txType "Remove offer"
     * Requirement: Only the seller of _tokenId can remove an offer.
     */
    function removeOffer(uint256 _tokenId) public {
        require(_owns(msg.sender, _tokenId), "The user doesn't own the token");
        Offer storage offer = offers[_tokenId];
        /*  delete the offer info */
        delete offer;
        /* Remove the offer in the mapping*/
        delete tokenIdToOffer[_tokenId];
        offers[offer.index].active = false;
        emit MarketTransaction("Remove offer", msg.sender, _tokenId);
    }

    /**
     * Executes the purchase of _tokenId.
     * Sends the funds to the seller and transfers the token using transferFrom in Kittycontract.
     * Emits the MarketTransaction event with txType "Buy".
     * Requirement: The msg.value needs to equal the price of _tokenId
     * Requirement: There must be an active offer for _tokenId
     */
    function buyKitty(uint256 _tokenId) public payable {
        Offer storage offer = offers[_tokenId];
        require(offer.active == true, "this offer is not active");
        require(msg.value == offer.price, "price error");

        /* we delete the offer info */
        delete offer;
        offer.active = false;

        /* Remove the offer in the mapping*/
        delete tokenIdToOffer[_tokenId];

        if (offer.price > 0) {
            offer.seller.transfer(offer.price);
        }
        _kittyContract.transferFrom(offer.seller, msg.sender, _tokenId);
        transferFrom(offer.seller, msg.sender, _tokenId);
        // to send funds
        emit MarketTransaction("Buy", msg.sender, tokenId);
    }

    function _createOffer(uint256 _price, uint256 _tokenId) private {
        Offer memory _offer = Offer({
            seller: msg.sender,
            price: uint256(_price),
            index: offers.length,
            tokenId: uint256(_tokenId),
            active: true
        });
        tokenIdToOffer[_tokenId] = _offer;
        offers.push(_offer);
        emit MarketTransaction("Create offer", msg.sender, _tokenId);
    }
}
