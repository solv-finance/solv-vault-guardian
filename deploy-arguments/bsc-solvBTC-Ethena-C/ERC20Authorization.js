module.exports = [
  "0x28eFB347e3dcA69C76B1aCE93AefeD38802adFf5",
  [
    [
      "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // BTCB
      [
        "0xb816018e5d421e8b809a4dc01af179d86056ebdf", // OpenEndFundShare
        "0xe16cec2f385ea7a382772334a44506a865f98562", // OpenEndFundRedemption
      ],
    ]
  ],
  [
    [
      "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // BTCB
      [
        "0x667cc3145f9f63bd796a1a62ef504aaa160550e5", // receiver
      ],
    ]
  ]
]

// npx hardhat verify --network bsc 0x71620D65743B972FA0bD90d65f6774DB1F3b7049 --constructor-args deploy-arguments/bsc-solvBTC-Ethena-C/ERC20Authorization.js