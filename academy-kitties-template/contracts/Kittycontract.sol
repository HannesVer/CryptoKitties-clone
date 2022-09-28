// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Kittycontract is IERC721, Ownable {
    uint256 public constant CREATION_LIMIT_GEN0 = 10;

    mapping(address => uint256) ownershipTokenCount;
    mapping(uint256 => address) public ownerofToken;
    // this will allow a third address to transfer token for you
    // there also exists an operator function allowing third party to transfer all your tokens --> below
    mapping(uint256 => address) public kittyIndexToApproved;
    //MYADDR => OPERATORADDR  => TRUE/FALSE
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor() public {
        _createKitty(0, 0, 0, uint256(-1), address(0)); //create cat number 0 to avoid problems with the 0 ID later on
    }

    string public constant kittyTokenName = "KittyToken";
    string public constant kittyTokenSymbol = "KT";

    bytes4 internal constant MAGIC_ERC721_RECEIVED =
        bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    event Birth(
        address owner,
        uint256 kittenId,
        uint256 mumId,
        uint256 dadId,
        uint256 genes
    );
    // event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    struct Kitty {
        uint256 genes;
        uint64 birthTime;
        uint32 mumId;
        uint32 dadId;
        uint16 generation;
    }

    Kitty[] kitties;
    // underscore ' _ ' before func or variable usually used to distinguish internal stuff
    uint256 public gen0Counter;

    // event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function breed(uint256 _dadId, uint256 _mumId) public returns (uint256) {
        require(_owns(msg.sender, _dadId), "you dont own this cat");
        require(_owns(msg.sender, _mumId), "you dont own this cat");
        (uint256 dadDna, , , , uint256 DadGeneration) = getKitty(_dadId);
        (uint256 mumDna, , , , uint256 MumGeneration) = getKitty(_mumId);
        uint256 newDna = _mixDna(dadDna, mumDna);
        uint256 newgeneration = 0;
        newgeneration = max(DadGeneration, MumGeneration) + 1;
        _createKitty(newDna, _mumId, _dadId, newgeneration, msg.sender);
    }

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool)
    {
        return (_interfaceId == _INTERFACE_ID_ERC721 ||
            _interfaceId == _INTERFACE_ID_ERC165);
    }

    function approve(address _approved, uint256 _tokenId) external override {
        require(_owns(msg.sender, _tokenId), "sorry you don't own this token");
        _approve(_tokenId, _approved);
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        kittyIndexToApproved[_tokenId] = _approved;
    }

    function setApprovalForAll(address _operator, bool _approved)
        public
        override
    {
        require(_operator != msg.sender);
        _setApprovalForAll(msg.sender, _operator, _approved);
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function _setApprovalForAll(
        address _from,
        address _operator,
        bool _approved
    ) public {
        _operatorApprovals[_from][_operator] = _approved;
    }

    function getApproved(uint256 _tokenId)
        public
        view
        override
        returns (address)
    {
        require(_tokenId < kitties.length, "Token does not exist");
        return kittyIndexToApproved[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[_owner][_operator];
    }

    function createKittyGen0(uint256 _genes) public onlyOwner {
        require(
            gen0Counter < CREATION_LIMIT_GEN0,
            "Can't make any more gen0 cats!"
        );
        gen0Counter++;
        _createKitty(_genes, 0, 0, 0, msg.sender);
        // write contract ,and implemnt ownable functionality
    }

    function _createKitty(
        uint256 _genes,
        uint256 _mumId,
        uint256 _dadId,
        uint256 _generation,
        address _owner
    ) private returns (uint256) {
        Kitty memory _kitty = Kitty({
            genes: _genes,
            birthTime: uint64(block.timestamp),
            mumId: uint32(_mumId),
            dadId: uint32(_dadId),
            generation: uint16(_generation)
        });
        kitties.push(_kitty);
        uint256 newKittenId = kitties.length - 1;
        emit Birth(_owner, newKittenId, _mumId, _dadId, _genes);
        _transfer(address(0), _owner, newKittenId);
        return newKittenId;
    }

    function getKitty(uint256 _kittyId)
        public
        view
        returns (
            // return statement in function declaration is equivalent to putting in a return statement
            //in the function body
            uint256 genes,
            uint256 birthTime,
            uint256 mumId,
            uint256 dadId,
            uint256 generation
        )
    {
        // writing 'memory' would mean function takes up more space than 'storage', storage is a pointer
        // memory would take a copy of the mapping, storage doesnt put in local memory, just points to mapping
        Kitty storage kitty = kitties[_kittyId];
        genes = kitty.genes;
        birthTime = uint256(kitty.birthTime);
        mumId = uint256(kitty.mumId);
        dadId = uint256(kitty.dadId);
        generation = uint256(kitty.generation);
    }

    function balanceOf(address owner)
        external
        view
        override
        returns (uint256 balance)
    {
        return ownershipTokenCount[owner];
    }

    function totalSupply() external view override returns (uint256 total) {
        return kitties.length;
    }

    function name() external view override returns (string memory tokenName) {
        return kittyTokenName;
    }

    function symbol()
        external
        view
        override
        returns (string memory tokenSymbol)
    {
        return kittyTokenSymbol;
    }

    function ownerOf(uint256 _tokenId)
        external
        view
        override
        returns (address owner)
    {
        return ownerofToken[_tokenId];
    }

    function transfer(address _to, uint256 _tokenId) external override {
        require(_to != address(0), "You cannot send to the null address");
        require(
            _to != address(this),
            "Dude you cannot send your token to the contract address"
        );
        require(_owns(msg.sender, _tokenId), "You do not own this token!");

        _transfer(msg.sender, _to, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        require(_isApprovedOrOwner(msg.sender, _from, _to, _tokenId));
        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        //  safeTransferFrom(_from, _to, _tokenId, "");
    }

    function _isApprovedOrOwner(
        address _spender,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal view returns (bool) {
        require(_owns(_from, _tokenId));
        //from is either msg.sender himself, or approved for that token, or msg.sender has approval for all tokens of from address
        require(_to != address(0));
        require(_tokenId < kitties.length, "Token does not exist");
        return (_spender == _from ||
            _approvedFor(_spender, _tokenId) ||
            isApprovedForAll(_from, msg.sender));
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external override {
        require(_isApprovedOrOwner(msg.sender, _from, _to, _tokenId));
        _safeTransfer(_from, _to, _tokenId, _data);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        ownershipTokenCount[_to]++;
        ownerofToken[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete kittyIndexToApproved[_tokenId];
        }

        emit Transfer(_from, _to, _tokenId);
    }

    function _approvedFor(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return kittyIndexToApproved[_tokenId] == _claimant;
    }

    function _safeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal {
        _transfer(_from, _to, _tokenId);
        require(
            _checkERC721Support(_from, _to, _tokenId, _data),
            "not supported!"
        );
    }

    function _checkERC721Support(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!_isContract(_to)) {
            return true;
        }
        bytes4 returnData = IERC721Receiver(_to).onERC721Received(
            msg.sender,
            _from,
            _tokenId,
            _data
        );
        return returnData == MAGIC_ERC721_RECEIVED;
    }

    function _owns(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return ownerofToken[_tokenId] == _claimant;
    }

    function _isContract(address _to) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        // returns true or false
        return size > 0;
    }

    function _mixDna(uint256 _dadDna, uint256 _mumDna)
        internal
        returns (uint256)
    {
        uint256[8] memory geneArray;
        uint8 random = uint8(block.timestamp % 255);
        uint256 i = 1;
        uint256 index = 7;

        for (i = 1; i <= 128; i = i * 2) {
            if (random & i != 0) {
                geneArray[index] = uint8(_mumDna % 100);
            } else {
                geneArray[index] = uint8(_dadDna % 100);
            }
            _mumDna = _mumDna / 100;
            _dadDna = _dadDna / 100;

            index = index - 1;
        }

        uint256 newGene;

        for (i = 0; i < 8; i++) {
            newGene = newGene + geneArray[i];
            if (i != 7) {
                newGene = newGene * 100;
            }
        }

        return newGene;
    }
}
