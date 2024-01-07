// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint tokenId) external;

    function transferFrom(address, address, uint) external;
}

contract EnglishAuction {
    event Start();
    event Bid(address indexed sender, uint amount); //indexed yapamamızın sebebı
    event WithDraw(address indexed sender, uint amount);
    event End(address high, uint256 maxAmount);
    IERC721 public immutable nft; //bu nft degısemez ve acık yaptık
    uint public immutable nftId; //nft ıd side degısemez

    address payable public immutable seller; //degısmez bır satıcı olusturduk
    uint32 public endAt; // biticegi süre satıcı strata bastıgında baslıycak sure
    bool public started; //basladımı
    bool public ended; //bittimi

    address public highestBidder; //en yuksek teklıfı verenın adresi
    uint public highestBid; //en yuksek teklifin adeti

    mapping(address => uint) public bids; // teklif verenlerin hepsı teklifi geri çekebilsinler diye

    constructor(address _nft, uint _nftId, uint _stardingBid) {
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable(msg.sender);
        highestBid = _stardingBid;
    }

    function start() external {
        require(msg.sender == seller, "not seller");
        require(!started, "started");

        started = true;
        endAt = uint32(block.timestamp + 7 days);
        nft.transferFrom(seller, address(this), nftId); // nft sahıplıgını satıcıdan bu contracta aktarıyoruz

        emit Start();
    }

    function bind() external payable {
        //Teklif verme işlemi
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "value < highest bid");

        if (highestBidder != address(0)) {
            //yanı ılk once hıc kayıt yok ıse gırme buraya
            bids[highestBidder] += highestBid; //en yuksekten yuksek geldıgı ıcınbunu artık buraya atıyoruz
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(msg.sender, msg.value);
    }

    function Withdraw() external {
        uint bal = bids[msg.sender]; //kullanıcın yatırdıgı parayı gosterır
        bids[msg.sender] = 0; //kullanıcı tum parasını cekecegı ıcın 0 lanır yatırdıgı para
        payable(msg.sender).transfer(bal); // para transferı yapılır
        emit WithDraw(msg.sender, bal);
    }

    function end() external {
        require(started, "not started"); //baslamıs olmalıdır
        require(!ended, "ended"); //bıtmemıs olamalıdır
        require(block.timestamp >= endAt, "not ended"); //zamanı dolammalıdır

        ended = true;
        if (highestBidder != address(0)) {
            //address 0 ıse bu nft ye kımse teklıf vermemıstır demek
            nft.transferFrom(address(this), highestBidder, nftId); //nft yi en yuksek teklıfı verene ver
            seller.transfer(highestBid); //satıcı parasını aldı
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}
