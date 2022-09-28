var web3 = new Web3(Web3.givenProvider);

var instance;
var user;
var contractAddress = "0x2f04dEf5D3B94Ef51088082b4C94f58C5765E0d4";
// $ used as a J query, checks when a page is loaded
$(document).ready(function () {
  window.ethereum.enable().then(function (accounts) {
    //call metamask's enable function, almost like a login prompt
    //then, whenever the user accepts, callback to .then() function that gives us our accounts
    //accounts we select almost always zero
    //instance is used similarly as in truffle console, to create contract isntance and call functions
    //abi: what functions does contact take, what parameters go in them, and what is expected to be returned?
    instance = new web3.eth.Contract(abi, contractAddress, { from: accounts[0] });
    user = accounts[0];
    console.log(instance);
    //callbacks: need to wait for response of ethereum node, {} for options object (dont have any here)
    instance.events.Birth().on('data', function (event) {
      console.log(event);
      let owner = event.returnValues.owner;
      let kittenId = event.returnValues.kittyId;
      let mumId = event.returnValues.mumId;
      let dadId = event.returnValues.dadId;
      let genes = event.returnValues.genes;
      $("kittyCreation").css("display", "block");
      $("kittyCreation").text("owner:" + owner
        + " kittyId:" + kittenId
        + " mumId:" + mumId
        + " dadId:" + dadId
        + " genes:" + genes)
    })
      .on('error', console.error);

  })
})
