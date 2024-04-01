module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const caller = (await deployments.get("arb-pilot-SolvVaultGuardianForSafe13"))
    .address;

  const spenders = [
    [
      "", // USDT
      [
        "", // OpenEndFundShare
        "", // OpenEndFundRedemption
      ],
    ],
  ];

  const receivers = [
    [
      "", // USDT
      [
        "", // CEX Recharge Address
      ],
    ],
  ];

  const deployName = "chain-name-ERC20Authorization";
  const authorization = await deploy(deployName, {
    from: deployer,
    contract: "ERC20Authorization",
    args: [caller, spenders, receivers],
    log: true,
  });

  console.log(`${deployName} deployed at ${authorization.address}`);
};

module.exports.tags = ["arb-pilot-ERC20Authorization"];
