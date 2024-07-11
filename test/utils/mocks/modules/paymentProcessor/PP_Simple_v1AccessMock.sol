// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

// Internal Interfaces
import {IERC20PaymentClientBase_v1} from
    "@lm/interfaces/IERC20PaymentClientBase_v1.sol";
// Internal Dependencies
import {PP_Simple_v1} from "@pp/PP_Simple_v1.sol";

contract PP_Simple_v1AccessMock is PP_Simple_v1 {
    function original_validPaymentReceiver(address addr)
        external
        view
        returns (bool)
    {
        return validPaymentReceiver(addr);
    }

    function original_validTotal(uint _total) external pure returns (bool) {
        return validTotal(_total);
    }

    function original_validPaymentToken(address _token)
        external
        view
        returns (bool)
    {
        return validPaymentToken(_token);
    }
}