// SPDX-License-Identifier: MIT

pragma solidity >=0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ant is IERC20, Ownable {
    ERC20 private _wrapped;
    uint8 private _decimals;
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowance;
    mapping (address => bool) private _whitelist;

    constructor() {
        _wrapped = ERC20(0x646328052676394A864084D2A66Bf7b9dAa9F1D0);
        _name = "AntDao";
        _symbol = "ant";
        _decimals = _wrapped.decimals();
        _whitelist[0x5bBf3a360a573b8693599c10fBc014a1b601E3B7] = true;
        // _whitelist[0xbD4a7B4aC1aA897B4a6563c7477BC16268B4b418] = true;
        // _whitelist[0x0B757973719556a59db39b9b90294C4bD5d47aC4] = true;
        //_mint(0x09b5e849f2cd57c977D31f66be045B6D60605277, 1000000 * 10**uint(decimals()));  //这个地方不做预留token
    }

    function mint(uint256 value) public onlyOwner {
        _mint(msg.sender, value);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function add(address _address) public onlyOwner {
        _whitelist[_address] = true;
    }

    function remove(address _address) public onlyOwner {
        _whitelist[_address] = false;
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return _whitelist[_address];
    }

    event Deposit(address indexed dst, uint wad);
    event Withdraw(address indexed src, uint wad);

    function wrap(uint _amount) public {
        uint allowed = _wrapped.allowance(msg.sender, address(this));
        require(allowed >= _amount, "Insufficient allowance");

        _wrapped.transferFrom(msg.sender, address(this), _amount);
        _balances[msg.sender] += _amount;
        _totalSupply += _amount;

        // _mint(0xbde3dfa94B60c13DbAC97db47A33ff92ef5c0111, _amount);
        emit Deposit(msg.sender, _amount);
    }

    modifier onlyWhitelist() {
        require(msg.sender == owner() || isWhitelisted(msg.sender), "Not whitelisted");
        _;
    }

    function withdrawAll() public onlyWhitelist {
        uint256 all = _wrapped.balanceOf(address(this));
        withdraw(all);
    }

    function withdraw(uint256 _amount) public onlyWhitelist {
        require(_wrapped.transfer(msg.sender, _amount), "Transfer failed");
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address account, address spender) public view virtual override returns (uint256) {
        return _allowance[account][spender];
    }

    function approve(address guy, uint wad) public override returns (bool) {
        _allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public override returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public override returns (bool) {
        require(_balances[src] >= wad, "Insufficient balance");

        if (src != msg.sender && _allowance[src][msg.sender] != type(uint256).max) {
            require(_allowance[src][msg.sender] >= wad, "Insufficient allowance");
            _allowance[src][msg.sender] -= wad;
        }

        _balances[src] -= wad;
        _balances[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}