module.exports = [
  "0xF25d16d2E49Bc1d247E87bc1EdB58DF516EfC084",
  [
    [
      "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // BTCB
      [
        "0xb816018e5d421e8b809a4dc01af179d86056ebdf", // OpenEndFundShare
        "0xe16cec2f385ea7a382772334a44506a865f98562", // OpenEndFundRedemption
      ],
    ],
  ],
  [
    [
      "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // BTCB
      [
        "0x667cc3145f9f63bd796a1a62ef504aaa160550e5", // receiver
      ],
    ],
  ],
];

// npx hardhat verify --network bsc 0xFB191Cd80C96E72F2065D8cdDE97933E6fecc384 --constructor-args deploy-arguments/bsc-solvBTC-Ethena/ERC20Authorization.js
