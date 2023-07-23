import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";

import ic_web3 "canister:ic_web3_copy";

shared(msg) actor class MultiSigWallet() {

  type Transaction = {
    to: Text;
    value: Nat64;
    var executed: Bool; // var?
  };

  type TxArray = Buffer.Buffer<Transaction>;
  type AddrArray = Buffer.Buffer<Text>;

  type Result = {
    #Err : Text;
    #Ok: Text;
  };
  type Result_1 = {
    #Err: Text;
	#Ok : Nat64;
  };
  
  let canister_owner = msg.caller;

  var owners = Buffer.Buffer<Text>(3);
  var required : Nat = 3; // enable input for this?

  let transactions : TxArray = Buffer.Buffer<Transaction>(3);
  
  let approved  = Buffer.Buffer<AddrArray>(3); // mapping from tx id => array of owners
  let approvals = Buffer.Buffer<Nat>(3); // mapping from tx id => number of approvals
  var initiated : Bool = false;

  public shared(msg) query func whoami(): async Text {
    return Principal.toText(msg.caller);
  };
  
  public func call_batch_request() : async Result {
    let result = await ic_web3.batch_request();
    return result;
  };

  public func call_get_block(number : Nat64) : async Result {
    let result = await ic_web3.get_block(number);
    return result;
  };

  public func call_get_canister_addr() : async Result {
    let result = await ic_web3.get_canister_addr();
    return result;
  };

  public func call_get_eth_balance(addr: Text) : async Result {
    let result = await ic_web3.get_eth_balance(addr: Text);
    return result;
  };

  public func call_get_eth_gas_price() : async Result {
    let result = await ic_web3.get_eth_gas_price();
    return result;
  };

  public func call_get_tx_count(addr: Text) : async Result_1 {
    let result = await ic_web3.get_tx_count(addr);
    return result;
  };

  func call_rpc_call(body: Text) : async Result {
    let result = await ic_web3.rpc_call(body);
    return result;
  };

  func call_send_eth(to: Text, value: Nat64, nonce: ?Nat64) : async Result {
    let result = await ic_web3.send_eth(to, value, nonce);
    return result;
  };

  func call_send_token(token_addr: Text, addr: Text, value: Nat64, nonce: ?Nat64) : async Result {
    let result = await ic_web3.send_token(token_addr, addr, value, nonce);
    return result;
  };

  public func call_token_balance(contract_addr: Text, addr: Text) : async Result {
    let result = await ic_web3.token_balance(contract_addr, addr);
    return result;
  };

  public shared(msg) func add_owner(new_owner : Text) : async () {
    assert (msg.caller == canister_owner); // "Only the canister owner can add a wallet owner"
	  assert (not Buffer.contains(owners, new_owner, Text.equal)); // "Already an owner"
	  owners.add(new_owner);
  };
  
  /*
  public query func list_owners() : async Text { // wish list function; version here did not compile
    return (Buffer.toText(owners, Text));
  };
  */
  
  // initialization function
  public shared(msg) func init(_required : Nat) : async () {
    assert (not initiated); // "Already initiated"
	  assert (msg.caller == canister_owner); // "Only the canister owner can initiate"
    assert (owners.size() > 0); // "Owners required"
    assert ((_required > 0) and (_required <= owners.size())); // "Invalid required number of owners"
    required := _required;
    initiated := true;
  };
  
  public shared(msg) func submit(_to : Text, _value : Nat64) : async Nat {
	  assert (initiated); // "Wallet not yet initiated"
    assert (Buffer.contains<Text>(owners, Principal.toText(msg.caller), Text.equal)); // "Can only be called by owners";
    let newRecord : Transaction = { to = _to; value = _value; var executed = false; };
    transactions.add(newRecord);
    let ownersApproved = Buffer.Buffer<Text>(3);
    approved.add(ownersApproved);
    approvals.add(0);
	  return (transactions.size() - 1); // returns transaction ID
  };

  public shared(msg) func approve(TxId : Nat) : async () {
    assert (Buffer.contains<Text>(owners, Principal.toText(msg.caller), Text.equal)); // "Can only be called by owners"
    assert (TxId < transactions.size()); // "No such transaction"
	  let _transaction = transactions.get(TxId);
    let _executed = _transaction.executed;
    assert (not _executed); // "Transaction already executed"
    let approvalArray = approved.get(TxId);
    assert (Buffer.contains<Text>(approvalArray, Principal.toText(msg.caller), Text.equal)); // "Transaction already approved by you"
    let thisEntry = approved.get(TxId);
    thisEntry.add(Principal.toText(msg.caller));
    approved.put(TxId, thisEntry);
    let thisTxApprovals = approvals.get(TxId);
    approvals.put(TxId, thisTxApprovals + 1);
  };

  public shared(msg) func execute(TxId : Nat) : async Result {
    assert (Buffer.contains<Text>(owners, Principal.toText(msg.caller), Text.equal)); // "Can only be called by owners"
    assert (TxId < transactions.size()); // "No such transaction"
    assert ((approved.get(TxId)).size() >= required); // "Not enough approvals"
    let thisTransaction = transactions.get(TxId);
	  let _executed = thisTransaction.executed;
    assert (not _executed); // "Transaction already executed"
    let _to = thisTransaction.to;
    let _value = thisTransaction.value;
    let _address = await call_get_canister_addr();
    let txExec = await call_send_eth(_to, _value, null);
    thisTransaction.executed := true;
    transactions.put(TxId, thisTransaction);
    return txExec;
  };

  public shared(msg) func revoke(TxId : Nat) : async () {
    assert (Buffer.contains<Text>(owners, Principal.toText(msg.caller), Text.equal)); // "Can only be called by owners"
    assert (TxId < transactions.size()); // "No such transaction"
    let _transaction = transactions.get(TxId);
    let _executed = _transaction.executed;
    assert (not _executed); // "Transaction already executed"
    let approvalArray = approved.get(TxId);
    assert(not Buffer.contains<Text>(approvalArray, Principal.toText(msg.caller), Text.equal)); // "Not already approved by you"
    let thisEntry = approved.get(TxId);
	  let _ix = Buffer.indexOf<Text>(Principal.toText(msg.caller), thisEntry, Text.equal);
	  let ix : Nat = switch _ix {
      case null 0;
      case (?nat) nat;
    };
    let x : Text = thisEntry.remove(ix);
    approved.put(TxId, thisEntry);
    let thisTxApprovals = approvals.get(TxId);
    approvals.put(TxId, thisTxApprovals - 1);
  };
}
