// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../VRC25/VRC25Gas.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/BaseOFTV2.sol" as BaseOFTV2Alias;

abstract contract OFTVRC25Gas is BaseOFTV2Alias.BaseOFTV2, VRC25Gas {
    uint internal immutable ld2sdRate;

    error InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _sharedDecimals,
        address _lzEndpoint
    ) VRC25Gas(_name,_symbol,_sharedDecimals) BaseOFTV2Alias.BaseOFTV2(_sharedDecimals, _lzEndpoint) {
        uint8 decimals = decimals();
        require(_sharedDecimals <= decimals, "OFT: sharedDecimals must be <= decimals");
        ld2sdRate = 10**(decimals - _sharedDecimals);
    }

    function supportsInterface(bytes4 interfaceId) public view override(BaseOFTV2Alias.BaseOFTV2, VRC25) returns (bool) {
        return BaseOFTV2Alias.BaseOFTV2.supportsInterface(interfaceId) || VRC25.supportsInterface(interfaceId);
    }

    /************************************************************************
     * public functions
     ************************************************************************/
    function circulatingSupply() public view virtual override returns (uint) {
        return totalSupply();
    }

    function token() public view virtual override returns (address) {
        return address(this);
    }

    /************************************************************************
     * internal functions
     ************************************************************************/
    function _debitFrom(
        address _from,
        uint16,
        bytes32,
        uint _amount
    ) internal virtual override returns (uint) {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint _amount
    ) internal virtual override returns (uint) {
        _mint(_toAddress, _amount);
        return _amount;
    }

    function _transferFrom(
        address _from,
        address _to,
        uint _amount
    ) internal virtual override returns (uint) {
        address spender = _msgSender();
        // if transfer from this contract, no need to check allowance
        if (_from != address(this) && _from != spender) _spendAllowance(_from, spender, _amount);
        _transfer(_from, _to, _amount);
        return _amount;
    }

    function _ld2sdRate() internal view virtual override returns (uint) {
        return ld2sdRate;
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value);
            }
        }
    }
}
