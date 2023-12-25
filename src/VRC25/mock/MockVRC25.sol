// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


import "../libraries/ECDSA.sol";
import "../libraries/EIP712.sol";

import "../VRC25Gas.sol";

contract MockVRC25 is VRC25Gas, EIP712 {
    using Address for address;

    constructor(string memory name, string memory symbol, uint8 decimal) VRC25Gas(name,symbol,decimal) EIP712("VRC25", "1") {
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
    function mint(address recipient, uint256 amount) external onlyOwner returns (bool) {
        _mint(recipient, amount);
        return true;
    }
}
