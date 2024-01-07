// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol";

contract TokenSwap {
    IERC20 public token1; //swap edılecek token1 ın adresı
    address public owner1; //swap edılecek token1 ın adeti
    uint public amount1; //swap edılecek token1 ın sahibi

    IERC20 public token2; //swap edılecek token2 ın adresı
    address public owner2; //swap edılecek token2 ın adeti
    uint public amount2; //swap edılecek token2 ın sahibi

    constructor(
        //Contract için gecerli bilgileri almalalım
        address _token1,
        address _owner1,
        uint _amount1,
        address _token2,
        address _owner2,
        uint _amount2
    ) {
        token1 = IERC20(_token1);
        owner1 = _owner1;
        amount1 = _amount1;
        token2 = IERC20(_token2);
        owner2 = _owner2;
        amount2 = _amount2;
    }

    function swap() public {
        require(msg.sender == owner1 || msg.sender == owner2, "Not authorized"); //Bu fonksıyonu swap yapıcaklardan herhangı bırı cagırıbılır
        require(
            token1.allowance(owner1, address(this)) >= amount1, //token1 in sahıbı bu contracta yeterli miktarda token kullanım ıznı verdımı
            "Token 1 allowance too low"
        );
        require(
            token2.allowance(owner2, address(this)) >= amount2, //token2 in sahıbı bu contracta yeterli miktarda token kullanım ıznı verdımı
            "Token 2 allowance too low"
        );

        _safeTransferFrom(token1, owner1, owner2, amount1); //token1 ı ow1 den ow2 ye gonder
        _safeTransferFrom(token2, owner2, owner1, amount2); //token 2 yi ow2 den ow1 e gonder
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint amount
    ) private {
        bool sent = token.transferFrom(sender, recipient, amount); //sender dan recipient e amount kadar token transferı yap
        require(sent, "Token transfer failed");
    }
}
