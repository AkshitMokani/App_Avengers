// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MarketPlace is ERC721
{
    IERC20 ERC20Token; // Our Custom Token
    uint nftId = 1; // NFT ID start from 1
    uint i = 0; // its for the For Loop
    address nftOwner; //store the address of NFT buyer
    address firstOwner; //for Royalty

    //Map NFT ID with First NFT Owner
    mapping(uint => address) public isFirstOwner;

    //check NFT is On Sell or Not.
    mapping(uint => bool) public isOn_Sell; 

    //Map the seller address : nftId : sellAmount
    mapping(address => mapping(uint => uint)) SellList;
    
    //Map nftId : sellAmount
    mapping(uint => uint) public IdAmount;
    
    //Map nftOwner address : sellAmount
    mapping(address => uint) public walletBalance;

    //Map NFT ID with Royalty.
    mapping(uint => uint) public RoyaltyPercentage;
    
    //Map Nft ID and Total Royalty.
    mapping(uint => uint) public totalRoyalty;

    uint[][] onSale; //2D array which store nftId and its Amount;

    mapping(uint => mapping(uint => uint[])) public arrayIndex;
    mapping (uint256 => uint256) public checkCounterWithNft;

    uint256 public counter = 1;
    uint256 public arrayCounter = 0;

    
    constructor(address _ERC20Token) ERC721("MyNFT", "mnft") 
    {
        ERC20Token = IERC20(_ERC20Token);
    }

    function safeMint() public payable
    {
        require(msg.value == 0.1 ether,"Amount must be 0.1 ether");
        _safeMint(msg.sender,nftId);
        isFirstOwner[nftId] = msg.sender;
        nftId++;
    }

    function sellNFT(uint _nftId, uint _amount, uint _royalty) public 
    {
        require(_royalty > 0 && _royalty <= 30,"Royalty must be in range of 0 to 30");
        require(balanceOf(msg.sender) >= 1, "Sorry, you don't have enough NFTs");
        require(msg.sender == ownerOf(_nftId), "Sorry, you don't own this NFT");
        require(_amount > 0, "Price must be greater than zero");
        require(!isOn_Sell[_nftId], "Already on sell list");
        
        RoyaltyPercentage[_nftId] = _royalty; // mapping of NFT id with %.

        // Set the approval for the marketplace contract to transfer the NFT
        approve(address(this), _nftId);
        nftOwner = msg.sender;

        SellList[nftOwner][_nftId] = _amount;
        IdAmount[_nftId] = _amount;
        isOn_Sell[_nftId] = true;
        onSale.push([_nftId, _amount]);
        arrayIndex[counter][_nftId] = onSale[arrayCounter];
        checkCounterWithNft[_nftId] = counter;
        counter ++;
        arrayCounter ++;
    }
    
    function buyNFT(uint _nftId, uint _amount, uint256 _counter) payable public returns (bool) 
    {
        require(IERC20(ERC20Token).balanceOf(msg.sender) >= _amount, "Not enough balance");
        require(msg.sender != ownerOf(_nftId), "You can't buy your NFT");
        require(ERC20Token.balanceOf(msg.sender) >= _amount, "Not enough balance");

        if (_amount == IdAmount[_nftId]) 
        {
            uint afterRoyalty = _amount - (_amount * RoyaltyPercentage[_nftId]) / 100;
            IERC20(ERC20Token).transferFrom(msg.sender, address(this), afterRoyalty);
            uint royaltyAmount = _amount - afterRoyalty;
            IERC20(ERC20Token).transferFrom(msg.sender,isFirstOwner[_nftId] ,royaltyAmount);
            transferFrom(ownerOf(_nftId), msg.sender, _nftId);
            walletBalance[ownerOf(_nftId)] += afterRoyalty;
            //totalRoyalty[_nftId] = _amount - afterRoyalty;
            totalRoyalty[_nftId] = totalRoyalty[_nftId] + (_amount - afterRoyalty);
            
            isOn_Sell[_nftId] = false;

            // Find the index of the NFT in the onSale array
            uint indexToRemove = findIndexInOnSale(_nftId);

            // Remove the NFT from the onSale array by swapping with the last element and reducing the array length
            uint lastIndex = onSale.length - 1;
            onSale[indexToRemove] = onSale[lastIndex];
            onSale.pop();

            // Update the arrayIndex mapping by setting the value to an empty array
            arrayIndex[_counter][_nftId] = new uint[](0);

            return true;
        }
        else
        {
            return false;
        }
    }

    // Helper function to find the index of an NFT in the onSale array
    function findIndexInOnSale(uint _nftId) internal  returns (uint) 
    {
        for ( i = 0; i < onSale.length; i++) 
        {
            if (onSale[i][0] == _nftId) 
            {
                return i;
            }
        }
        revert("NFT not found in onSale array");
    }


    function withdraw() public payable 
    {
        payable(address(this)).transfer(walletBalance[msg.sender]);
        //payable(address(this)).transfer(totalRoyalty[_nftId]);
    }

    function viewOnSale() public view returns (uint[][] memory) 
    {
        return onSale;
    }
}


//https://www.loom.com/share/552b4760324e40938c0510f836bad605?sid=a6fdeee5-7d0a-498c-8854-19bd64d19be5
//https://www.loom.com/share/df025a94f5e445c1b4876d545a8efaed?sid=1e3f20e7-fdc8-47a9-8442-f23ae002f21f