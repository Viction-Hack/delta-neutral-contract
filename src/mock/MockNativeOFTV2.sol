// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "./OFTV2.sol";

contract MOCKNativeOFTV2 is OFTV2, ReentrancyGuard {
    uint256 public outboundAmount;

    event Deposit(address indexed _dst, uint256 _amount);
    event Withdrawal(address indexed _src, uint256 _amount);

    constructor(string memory _name, string memory _symbol, uint8 _sharedDecimals, address _lzEndpoint)
        OFTV2(_name, _symbol, _sharedDecimals, _lzEndpoint)
    {}

    /**
     *
     * public functions
     *
     */
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        LzCallParams calldata _callParams
    ) public payable virtual override {
        _send(
            _from,
            _dstChainId,
            _toAddress,
            _amount,
            _callParams.refundAddress,
            _callParams.zroPaymentAddress,
            _callParams.adapterParams
        );
    }

    function sendAndCall(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        bytes calldata _payload,
        uint64 _dstGasForCall,
        LzCallParams calldata _callParams
    ) public payable virtual override {
        _sendAndCall(
            _from,
            _dstChainId,
            _toAddress,
            _amount,
            _payload,
            _dstGasForCall,
            _callParams.refundAddress,
            _callParams.zroPaymentAddress,
            _callParams.adapterParams
        );
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(balanceOf(msg.sender) >= _amount, "NativeOFTV2: Insufficient balance.");
        _burn(msg.sender, _amount);
        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, "NativeOFTV2: failed to unwrap");
        emit Withdrawal(msg.sender, _amount);
    }

    function withdraw(address _to, uint256 _amount) external nonReentrant {
        require(balanceOf(msg.sender) >= _amount, "NativeOFTV2: Insufficient balance.");
        _burn(msg.sender, _amount);
        (bool success,) = _to.call{value: _amount}("");
        require(success, "NativeOFTV2: failed to unwrap");
        emit Withdrawal(_to, _amount);
    }

    function _send(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual override returns (uint256 amount) {
        _checkGasLimit(_dstChainId, PT_SEND, _adapterParams, NO_EXTRA_GAS);

        (amount,) = _removeDust(_amount);
        require(amount > 0, "NativeOFTV2: amount too small");
        uint256 messageFee = _debitFromNative(_from, amount);

        bytes memory lzPayload = _encodeSendPayload(_toAddress, _ld2sd(amount));
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, messageFee);

        emit SendToChain(_dstChainId, _from, _toAddress, amount);
    }

    function _sendAndCall(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        bytes memory _payload,
        uint64 _dstGasForCall,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual override returns (uint256 amount) {
        _checkGasLimit(_dstChainId, PT_SEND_AND_CALL, _adapterParams, _dstGasForCall);

        (amount,) = _removeDust(_amount);
        require(amount > 0, "NativeOFTV2: amount too small");
        uint256 messageFee = _debitFromNative(_from, amount);

        // encode the msg.sender into the payload instead of _from
        bytes memory lzPayload =
            _encodeSendAndCallPayload(msg.sender, _toAddress, _ld2sd(amount), _payload, _dstGasForCall);
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, messageFee);

        emit SendToChain(_dstChainId, _from, _toAddress, amount);
    }

    function _debitFromNative(address _from, uint256 _amount) internal returns (uint256 messageFee) {
        outboundAmount += _amount;
        messageFee = msg.sender == _from ? _debitMsgSender(_amount) : _debitMsgFrom(_from, _amount);
    }

    function _debitMsgSender(uint256 _amount) internal returns (uint256 messageFee) {
        uint256 msgSenderBalance = balanceOf(msg.sender);

        if (msgSenderBalance < _amount) {
            require(msgSenderBalance + msg.value >= _amount, "NativeOFTV2: Insufficient msg.value");

            // user can cover difference with additional msg.value ie. wrapping
            uint256 mintAmount = _amount - msgSenderBalance;
            _mint(address(msg.sender), mintAmount);

            // update the messageFee to take out mintAmount
            messageFee = msg.value - mintAmount;
        } else {
            messageFee = msg.value;
        }

        _transfer(msg.sender, address(this), _amount);
        return messageFee;
    }

    function _debitMsgFrom(address _from, uint256 _amount) internal returns (uint256 messageFee) {
        uint256 msgFromBalance = balanceOf(_from);

        if (msgFromBalance < _amount) {
            require(msgFromBalance + msg.value >= _amount, "NativeOFTV2: Insufficient msg.value");

            // user can cover difference with additional msg.value ie. wrapping
            uint256 mintAmount = _amount - msgFromBalance;
            _mint(address(msg.sender), mintAmount);

            // transfer the differential amount to the contract
            _transfer(msg.sender, address(this), mintAmount);

            // overwrite the _amount to take the rest of the balance from the _from address
            _amount = msgFromBalance;

            // update the messageFee to take out mintAmount
            messageFee = msg.value - mintAmount;
        } else {
            messageFee = msg.value;
        }

        _spendAllowance(_from, msg.sender, _amount);
        _transfer(_from, address(this), _amount);
        return messageFee;
    }

    function _creditTo(uint16, address _toAddress, uint256 _amount) internal override returns (uint256) {
        outboundAmount -= _amount;
        _burn(address(this), _amount);
        (bool success,) = _toAddress.call{value: _amount}("");
        require(success, "NativeOFTV2: failed to _creditTo");
        return _amount;
    }

    receive() external payable {
        deposit();
    }
}
