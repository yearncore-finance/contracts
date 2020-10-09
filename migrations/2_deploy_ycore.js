const YCore = artifacts.require("YCore");

module.exports = async function (deployer, _network) {
  await deployer.deploy(YCore, "0x584420AD584CD8880EC5d5e0f2042462AeC3aB47");
};
