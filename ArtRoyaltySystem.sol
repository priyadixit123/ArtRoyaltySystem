// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ArtRoyaltySystem {
    struct Art {
        string artId;        // Unique identifier for the art
        address artist;      // Artist's Ethereum address
        address currentOwner;// Current owner's address
        uint256 price;       // Current sale price
        uint8 royalty;       // Royalty percentage for the artist
    }

    mapping(string => Art) public artworks; // Map art ID to Art struct
    mapping(address => string[]) public ownerArtworks; // Map owner to their artworks

    event ArtRegistered(string artId, address artist, uint8 royalty);
    event ArtTransferred(string artId, address from, address to, uint256 price);
    event RoyaltyPaid(string artId, address artist, uint256 royaltyAmount);

    // Modifier to ensure only the artist or owner can transfer
    modifier onlyOwnerOrArtist(string memory _artId) {
        require(msg.sender == artworks[_artId].currentOwner || msg.sender == artworks[_artId].artist, "Only owner or artist can transfer.");
        _;
    }

    // Register a new artwork with a royalty percentage
    function registerArt(string memory _artId, uint8 _royalty) public {
        require(artworks[_artId].artist == address(0), "Art already registered.");
        require(_royalty <= 100, "Royalty percentage must be between 0 and 100.");

        artworks[_artId] = Art({
            artId: _artId,
            artist: msg.sender,
            currentOwner: msg.sender,
            price: 0,
            royalty: _royalty
        });

        ownerArtworks[msg.sender].push(_artId);

        emit ArtRegistered(_artId, msg.sender, _royalty);
    }

    // Transfer ownership of art
    function transferArt(string memory _artId, address _newOwner, uint256 _salePrice) public onlyOwnerOrArtist(_artId) {
        require(_newOwner != address(0), "New owner cannot be zero address.");
        require(_salePrice > 0, "Sale price must be greater than zero.");

        Art memory art = artworks[_artId];
        uint256 royaltyAmount = (_salePrice * art.royalty) / 100;
        uint256 sellerAmount = _salePrice - royaltyAmount;

        // Pay the artist their royalty
        payable(art.artist).transfer(royaltyAmount);
        emit RoyaltyPaid(_artId, art.artist, royaltyAmount);

        // Pay the seller
        payable(art.currentOwner).transfer(sellerAmount);

        // Transfer ownership
        artworks[_artId].currentOwner = _newOwner;
        artworks[_artId].price = _salePrice;

        // Update ownership mappings
        _removeArtFromOwner(msg.sender, _artId);
        ownerArtworks[_newOwner].push(_artId);

        emit ArtTransferred(_artId, msg.sender, _newOwner, _salePrice);
    }

    // Internal function to remove artwork from the owner's list
    function _removeArtFromOwner(address _owner, string memory _artId) internal {
        uint256 length = ownerArtworks[_owner].length;
        for (uint256 i = 0; i < length; i++) {
            if (keccak256(abi.encodePacked(ownerArtworks[_owner][i])) == keccak256(abi.encodePacked(_artId))) {
                ownerArtworks[_owner][i] = ownerArtworks[_owner][length - 1];
                ownerArtworks[_owner].pop();
                break;
            }
        }
    }

    // View artist of a given art piece
    function viewArtist(string memory _artId) public view returns (address) {
        return artworks[_artId].artist;
    }

    // View current owner of a given art piece
    function viewCurrentOwner(string memory _artId) public view returns (address) {
        return artworks[_artId].currentOwner;
    }

    // View the royalty percentage for a given art piece
    function viewRoyalty(string memory _artId) public view returns (uint8) {
        return artworks[_artId].royalty;
    }

    // Fallback function to receive Ether
    receive() external payable {}
}

    
  
