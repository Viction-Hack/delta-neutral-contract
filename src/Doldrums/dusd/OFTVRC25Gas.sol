// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../VRC25/VRC25Gas.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/BaseOFTV2.sol" as BaseOFTV2Alias;

abstract contract OFTVRC25Gas is BaseOFTV2Alias.BaseOFTV2, VRC25Gas {
    uint256 internal immutable ld2sdRate;

    error InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    constructor(string memory _name, string memory _symbol, uint8 _sharedDecimals, address _lzEndpoint)
        VRC25Gas(_name, _symbol, _sharedDecimals)
        BaseOFTV2Alias.BaseOFTV2(_sharedDecimals, _lzEndpoint)
        BaseOFTV2Alias.Ownable(msg.sender)
    {
        uint8 decimals = decimals();
        require(_sharedDecimals <= decimals, "OFT: sharedDecimals must be <= decimals");
        ld2sdRate = 10 ** (decimals - _sharedDecimals);
    }

    /**
     *
     * VRC25Gas overrides
     *
     */

    function owner() public view virtual override(BaseOFTV2Alias.Ownable, VRC25) returns (address) {
        return BaseOFTV2Alias.Ownable.owner();
    }

    function transferOwnership(address newOwner) public virtual override(BaseOFTV2Alias.Ownable, VRC25) onlyOwner {
        BaseOFTV2Alias.Ownable.transferOwnership(newOwner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(BaseOFTV2Alias.BaseOFTV2, VRC25)
        returns (bool)
    {
        return BaseOFTV2Alias.BaseOFTV2.supportsInterface(interfaceId) || VRC25.supportsInterface(interfaceId);
    }

    /**
     *
     * public functions
     *
     */
    function circulatingSupply() public view virtual override returns (uint256) {
        return totalSupply();
    }

    function token() public view virtual override returns (address) {
        return address(this);
    }

    /**
     *
     * internal functions
     *
     */
    function _debitFrom(address _from, uint16, bytes32, uint256 _amount) internal virtual override returns (uint256) {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    function _creditTo(uint16, address _toAddress, uint256 _amount) internal virtual override returns (uint256) {
        _mint(_toAddress, _amount);
        return _amount;
    }

    function _transferFrom(address _from, address _to, uint256 _amount) internal virtual override returns (uint256) {
        address spender = _msgSender();
        // if transfer from this contract, no need to check allowance
        if (_from != address(this) && _from != spender) _spendAllowance(_from, spender, _amount);
        _transfer(_from, _to, _amount);
        return _amount;
    }

    function _ld2sdRate() internal view virtual override returns (uint256) {
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

    function sendFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint256 _amount) public payable virtual {
        bytes memory packedData = abi.encodePacked(uint16(1), uint256(200000));

        _send(_from, _dstChainId, _toAddress, _amount, payable(_from), address(0), packedData);
    }

    receive() external payable {}

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
