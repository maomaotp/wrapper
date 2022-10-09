// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ANTIDO is Ownable {
    using SafeMath for uint256;

    ERC20 public X = ERC20(0x700eb171312f11B98236ACBeF9A320FA7d331d80);
    ERC20 public U = ERC20(0x55d398326f99059fF775485246999027B3197955);

    event Swap(address, uint256, uint256);

    function swap(uint256 amountU) public {
        uint256 amountX = this.U2X(amountU);

        require(this.allowanceU(msg.sender) >= amountU, "Allowance too low");
        require(this.balanceX() >= amountX, "Contract balance too low");

        _safeTransferFrom(U, msg.sender, address(this), amountU);
        _safeTransfer(X, msg.sender, amountX);

        emit Swap(msg.sender, amountU, amountX);
    }

    function exponent() public view returns (uint8) {
        return U.decimals() - X.decimals();
    }

    function U2X(uint256 amount) public view returns (uint256) {
        uint a = 333;
        uint b = 50;
        return a/b * amount / this.UperX();
    }

    function UperX() public view returns (uint256) {
        return 333/50 ** this.exponent();
    }

    function withdrawU() public onlyOwner {
        _safeTransfer(U, msg.sender, this.balanceU());
    }

    function withdrawX() public onlyOwner {
        _safeTransfer(X, msg.sender, this.balanceX());
    }

    function depositX(uint256 amount) public {
        require(this.allowanceX(msg.sender) >= amount, "Allowance too low");
        _safeTransferFrom(X, msg.sender, address(this), amount);
    }

    function destroy() public onlyOwner {
        if (this.balanceU() > 0){
            withdrawU();
        }
        if (this.balanceX() > 0){
            withdrawX();
        }
        selfdestruct(payable(msg.sender));
    }

    function allowanceU(address owner) public view returns (uint256) {
        return U.allowance(owner, address(this));
    }

    function allowanceX(address owner) public view returns (uint256) {
        return X.allowance(owner, address(this));
    }

    function balanceU() public view returns (uint256) {
        return U.balanceOf(address(this));
    }

    function balanceX() public view returns (uint256) {
        return X.balanceOf(address(this));
    }

    function _safeTransferFrom(IERC20 token, address sender, address recipient, uint256 amount) private {
        require(token.transferFrom(sender, recipient, amount), "Token transfer failed");
    }

    function _safeTransfer(IERC20 token, address recipient, uint256 amount) private {
        require(token.transfer(recipient, amount), "Token transfer failed");
    }
}
