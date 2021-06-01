// // SPDX-FileCopyrightText: 2020 Tenderize <info@tenderize.me>

// // SPDX-License-Identifier: GPL-3.0

// /* See contracts/COMPILERS.md */
pragma solidity ^0.8.0;

import "../utils/MathUtils.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Shares {
    using SafeMath for uint256;
    struct CapTable {
        uint256 totalShares;
        uint256 totalTokens;
        mapping (address => uint256) shares;
    }

    function buyShares(CapTable storage _capTable, uint256 _tokens, address _buyer) internal returns (uint256 shares) {
        shares = tokensToShares(_capTable, _tokens);
        _capTable.totalTokens = _capTable.totalTokens.add(_tokens);
        _capTable.totalShares = _capTable.totalShares.add(shares);
        _capTable.shares[_buyer] = _capTable.shares[_buyer].add(shares);

    }

    function sellShares(CapTable storage _capTable, uint256 _shares, address _seller) internal returns (uint256 tokens) {
        tokens = sharesToTokens(_capTable, _shares);
        _capTable.totalTokens = _capTable.totalTokens.sub(tokens);
        _capTable.totalShares = _capTable.totalShares.sub(_shares);
        _capTable.shares[_seller] = _capTable.shares[_seller].sub(_shares);
    }

    function sharesToTokens(CapTable storage _capTable, uint256 _shares) internal view returns (uint256 tokens) {
        uint256 totalTokens = _capTable.totalTokens;
        uint256 totalShares = _capTable.totalShares;

        if (totalShares == 0) {
            return 0;
        }

        return PreciseMathUtils.percOf(_shares, totalTokens, totalShares);
    }

    function tokensToShares(CapTable storage _capTable, uint256 _tokens) internal view returns (uint256 shares) {
        uint256 totalTokens = _capTable.totalTokens;
        uint256 totalShares = _capTable.totalShares;

        if (totalTokens == 0) {
            return 0;
        }

        if (totalShares == 0) {
            return _tokens;
        }

        return PreciseMathUtils.percOf(_tokens, totalShares, totalTokens);
    }
}