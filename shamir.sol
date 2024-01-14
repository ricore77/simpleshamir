// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ShamirSecretSharing {
    uint256 private constant prime = 115792089237316195423570985008687907853269984665640564039457584007913129639747;

    function calculateShare(uint256 secret, uint256 x, uint256[] memory coefficients) public pure returns (uint256) {
        require(coefficients.length > 0, "Coefficients array must not be empty");

        uint256 result = 0;
        uint256 xi = 1;

        for (uint256 i = 0; i < coefficients.length; i++) {
            result = (result + coefficients[i] * xi) % prime;
            xi = (xi * x) % prime;
        }

        return (result + secret) % prime;
    }

    function reconstructSecret(uint256[] memory x, uint256[] memory y) public pure returns (uint256) {
        require(x.length == y.length && x.length > 0, "Invalid input arrays");

        uint256 result = 0;

        for (uint256 i = 0; i < x.length; i++) {
            uint256 term = y[i];
            for (uint256 j = 0; j < x.length; j++) {
                if (j != i) {
                    term = (term * inverse(x[i] - x[j])) % prime;
                }
            }
            result = (result + term) % prime;
        }

        return result;
    }

    function inverse(uint256 a) public pure returns (uint256) {
        uint256 m = prime;
        if (a < 0) a = a + m;
        uint256 m0 = m;
        uint256 y = 0;
        uint256 x = 1;

        while (a > 1 && m > 0) {
            uint256 q = a / m;
            uint256 t = m;

            m = a % m;
            a = t;
            t = y;

            y = x - q * y;
            x = t;
        }

        if (a != 1) return 0;
        if (x < 0) x = x + m0;

        return x;
    }
}

contract SecretSharingExample {
    ShamirSecretSharing public secretSharingContract;

    constructor() {
        secretSharingContract = new ShamirSecretSharing();
    }

    function shareSecret(uint256 secret, uint256 numShares, uint256 threshold) public returns (uint256[] memory, uint256[] memory) {
        require(threshold <= numShares, "Threshold must be less than or equal to the number of shares");

        uint256[] memory xValues = new uint256[](numShares);
        uint256[] memory yValues = new uint256[](numShares);

        // Criação de coeficientes aleatórios para o polinômio
        uint256[] memory coefficients = new uint256[](threshold);
        for (uint256 i = 0; i < threshold; i++) {
            coefficients[i] = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, i)));
        }

        // Calcula os valores (x, y) para cada parte
        for (uint256 j = 0; j < numShares; j++) {
            xValues[j] = j + 1;
            yValues[j] = secretSharingContract.calculateShare(secret, xValues[j], coefficients);
        }

        return (xValues, yValues);
    }

    function reconstructSecret(uint256[] memory xValues, uint256[] memory yValues, uint256 threshold) public view returns (uint256) {
        require(xValues.length == yValues.length && xValues.length > 0, "Invalid input arrays");

        return secretSharingContract.reconstructSecret(xValues, yValues);
    }
}
