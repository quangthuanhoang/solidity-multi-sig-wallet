const MultiSigWallet = artifacts.require("MultiSigWallet");

module.exports = function (deployer, network, accounts) {
    const owners = ["0x5375b016fdef1fdfe41bc7e69699bdbb0398686b", "0x9cbfcd672e8a2d63a9b1ee744d78bbf2df5887e0","0x2c1e0bd7751556c47e394a6bf5b3c84975a35d99"]
    const numComfirmationsRequired = 2
    deployer.deploy(MultiSigWallet, owners, numComfirmationsRequired, { from: "0x9cbfcd672e8a2d63a9b1ee744d78bbf2df5887e0"});

};
