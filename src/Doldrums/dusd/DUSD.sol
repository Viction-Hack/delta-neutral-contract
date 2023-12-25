// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "../../VRC25/libraries/ECDSA.sol";
import "../../VRC25/libraries/EIP712.sol";

import "../../VRC25/VRC25Gas.sol";

contract DUSD is VRC25Gas, EIP712 {
    using Address for address;

    string public constant NAME = "Doldrums USD";
    string public constant SYMBOL = "DUSD";
    uint8 public constant DECIMALS = 18;
    address public controller;

    error InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    constructor(address _controller) VRC25Gas(NAME,SYMBOL,DECIMALS) EIP712("VRC25", "1") {
        controller = _controller;
    }

    modifier onlyController() {
        require(msg.sender == controller, "Vault: not controller");
        _;
    }

    /**
     * @notice Calculate fee required for action related to this token
     * @param value Amount of fee
     */
    function _estimateFee(uint256 value) internal view override returns (uint256) {
        return minFee();
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IVRC25).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Issues `amount` tokens to the designated `address`.
     *
     * Can only be called by the current owner.
     */
    function mint(address recipient, uint256 amount) external onlyController returns (bool) {
        _mint(recipient, amount);
        return true;
    }

    function burn(address account, uint256 amount) external onlyController returns (bool) {
        if (account != msg.sender) {
            _spendAllowance(account, msg.sender, amount);
        }
        _burn(account, amount);
        emit Transfer(account, address(0), amount);
        return true;
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
