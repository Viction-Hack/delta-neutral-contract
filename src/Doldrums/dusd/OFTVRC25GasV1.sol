pragma solidity ^0.8.0;

import "../../VRC25/VRC25Gas.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/v1/OFTCore.sol" as OFTCoreAlias;

abstract contract OFTVRC25Gas is OFTCoreAlias.OFTCore, VRC25Gas {
    error InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    constructor(string memory _name, string memory _symbol, uint8 decimals, address _lzEndpoint)
        VRC25Gas(_name, _symbol, decimals)
        OFTCoreAlias.OFTCore(_lzEndpoint)
        OFTCoreAlias.Ownable(msg.sender)
    {}

    function owner() public view virtual override(OFTCoreAlias.Ownable, VRC25) returns (address) {
        return OFTCoreAlias.Ownable.owner();
    }

    function transferOwnership(address newOwner) public virtual override(OFTCoreAlias.Ownable, VRC25) onlyOwner {
        OFTCoreAlias.Ownable.transferOwnership(newOwner);
    }

    function supportsInterface(bytes4 interfaceId) public view override(OFTCoreAlias.OFTCore, VRC25) returns (bool) {
        return OFTCoreAlias.OFTCore.supportsInterface(interfaceId) || VRC25.supportsInterface(interfaceId);
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

    function _debitFrom(address _from, uint16, bytes memory, uint256 _amount)
        internal
        virtual
        override
        returns (uint256)
    {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    function _creditTo(uint16, address _toAddress, uint256 _amount) internal virtual override returns (uint256) {
        _mint(_toAddress, _amount);
        return _amount;
    }

    /**
     *
     * internal functions
     *
     */

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

    function sendFrom(address _from, uint16 _dstChainId, bytes calldata _toAddress, uint256 _amount)
        public
        payable
        virtual
    {
        bytes memory adapterParams = abi.encodePacked(uint16(1), uint256(225000));

        _send(_from, _dstChainId, _toAddress, _amount, payable(_from), address(0), adapterParams);
    }

    function _send(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual override {
        uint256 amount = _debitFrom(_from, _dstChainId, _toAddress, _amount);

        bytes memory lzPayload = abi.encode(PT_SEND, _toAddress, amount);

        (uint256 nativeFee, uint256 zroFee) =
            lzEndpoint.estimateFees(_dstChainId, address(this), lzPayload, false, _adapterParams);

        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, nativeFee);

        emit SendToChain(_dstChainId, _from, _toAddress, amount);
    }

    receive() external payable {}

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // @dev WARNING public mint function, do not use this in production
    function mintTokens(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}
