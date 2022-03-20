const CoinFlip = artifacts.require("CoinFlip")

contract("CoinFlip", (accounts) => {
  before(async () => {
    _contract = await CoinFlip.deployed()
    console.log(accounts[0])
    console.log(await _contract.owner())
  })

  it("Should be deployed", async () => {
    expect(_contract).to.exist
    expect(_contract.address).to.exist
  })

  it("Should be able to insert and show funds", async () => {
    await _contract.insertFunds({ value: web3.utils.toWei("5", "ether") })
    const funds = await _contract.showFunds()

    expect(funds.toString()).to.equal(web3.utils.toWei("5", "ether"))
  });

  it("Should be able to flip", async () => {
    const bet = await _contract.placeBet(true, { value: web3.utils.toWei("0.2", "ether") })
    
    assert.isTrue(bet.logs[0].event == 'resultInfo')
  })

  it("Should be able to flip multiple times", async () => {
    let betsCounter = await _contract.betsCounter.call()
    expect(betsCounter.toString()).to.equal('1')

    const amount = web3.utils.toWei("0.1", "ether")

    await _contract.placeBet(false, {value: amount, from: accounts[4]})
    await _contract.placeBet(true, {value: amount, from: accounts[3]})

    betsCounter = await _contract.betsCounter.call()
    expect(betsCounter.toString()).to.equal('3')
  })

  it("Should be able to withdraw funds", async() => {
    const initialFunds = Number((await _contract.showFunds()).toString())
    await _contract.withdrawFunds(50)
    const remainingFunds = Number((await _contract.showFunds()).toString())
    
    expect(initialFunds).to.equal(remainingFunds * 2)
  })
})
