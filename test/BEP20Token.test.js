const BEP20Token = artifacts.require("BEP20Token");

contract("BEP20Token", accounts => {
    const [admin, user1, user2] = accounts;
    let token;

    const name = "GALAI";
    const symbol = "GAL";
    const cap = web3.utils.toWei('1000000', 'ether'); // 1 million tokens
    const feeRate = 100; // 1%
    const feeRecipient = user2;

    beforeEach(async () => {
        token = await BEP20Token.new(name, symbol, cap, feeRate, feeRecipient);
    });

    it("should correctly initialize token properties", async () => {
        assert.equal(await token.name(), name, "Token name mismatch");
        assert.equal(await token.symbol(), symbol, "Token symbol mismatch");
        assert.equal((await token.cap()).toString(), cap, "Token cap mismatch");
    });

    it("should allow anyone to mint within cap", async () => {
        const mintAmount = web3.utils.toWei('500000', 'ether'); // 500,000 tokens
        await token.mint(user1, mintAmount, { from: user1 });
        assert.equal((await token.balanceOf(user1)).toString(), mintAmount, "Minting failed");
    });

    it("should enforce ownership limit", async () => {
        const overLimitAmount = web3.utils.toWei('510000', 'ether'); // 510,000 tokens, over 5% limit
        try {
            await token.mint(user1, overLimitAmount, { from: user1 });
            assert.fail("Minted amount exceeds ownership limit");
        } catch (error) {
            assert.include(error.message, "OwnershipLimitExceeded", "Expected ownership limit exceeded error");
        }
    });

    // Additional tests can be added here to cover transfer, fee deduction, etc.
});