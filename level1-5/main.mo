import Result "mo:base/Result";
import TrieMap "mo:base/TrieMap";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Text "mo:base/Text";

// Define the DAO actor class
actor class DAO()  {
    // DAO basic information
    let name : Text = "Motoko Bootcamp DAO";
    var manifesto : Text = "Empower the next wave of builders to make the Web3 revolution a reality";

    // List of goals for the DAO
    let goals : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);

    // Get the name of the DAO
    public shared query func getName() : async Text {
        return name;
    };

    // Get the manifesto of the DAO
    public shared query func getManifesto() : async Text {
        return manifesto;
    };

    // Set or update the DAO's manifesto
    public func setManifesto(newManifesto : Text) : async () {
        manifesto := newManifesto;
        return;
    };

    // Add a new goal to the DAO's list of goals
    public func addGoal(newGoal : Text) : async () {
        goals.add(newGoal);
        return;
    };

    // Retrieve the list of goals set by the DAO
    public shared query func getGoals() : async [Text] {
        return Buffer.toArray(goals);
    };

    ///////////////
    // LEVEL #2 //
    /////////////

    // Define the structure of a DAO member
    public type Member = {
        name : Text;
        age : Nat;
    };
    public type Result<A, B> = Result.Result<A, B>;
    public type HashMap<A, B> = HashMap.HashMap<A, B>;

    // HashMap to store DAO members, keyed by their Principal
    let dao : HashMap<Principal, Member> = HashMap.HashMap<Principal, Member>(0, Principal.equal, Principal.hash);

    // Add a new member to the DAO
    public shared ({ caller }) func addMember(member : Member) : async Result<(), Text> {
        switch (dao.get(caller)) {
            case (?member) {
                return #err("Already a member");
            };
            case (null) {
                dao.put(caller, member);
                return #ok(());
            };
        };
    };

    // Update the details of an existing DAO member
    public shared ({ caller }) func updateMember(member : Member) : async Result<(), Text> {
        switch (dao.get(caller)) {
            case (?member) {
                dao.put(caller, member);
                return #ok(());
            };
            case (null) {
                return #err("Not a member");
            };
        };
    };

    // Remove a member from the DAO
    public shared ({ caller }) func removeMember() : async Result<(), Text> {
        switch (dao.get(caller)) {
            case (?member) {
                dao.delete(caller);
                return #ok(());
            };
            case (null) {
                return #err("Not a member");
            };
        };
    };

    // Retrieve the details of a specific DAO member
    public query func getMember(p : Principal) : async Result<Member, Text> {
        switch (dao.get(p)) {
            case (?member) {
                return #ok(member);
            };
            case (null) {
                return #err("Not a member");
            };
        };
    };

    // Get all members of the DAO
    public query func getAllMembers() : async [Member] {
        return Iter.toArray(dao.vals());
    };

    // Count the total number of members in the DAO
    public query func numberOfMembers() : async Nat {
        return dao.size();
    };

    ///////////////
    // LEVEL #3 //
    /////////////

    // Define the structure of an account
    public type Subaccount = Blob;
    public type Account = {
        owner : Principal;
        subaccount : ?Subaccount;
    };

    // Token details
    let nameToken = "Motoko Bootcamp Token";
    let symbolToken = "MBT";

    // TrieMap to keep track of token balances
    // let ledger : TrieMap.TrieMap<Account, Nat> = TrieMap.TrieMap(Account.accountsEqual, Account.accountsHash);

    // Retrieve the name of the token
    public query func tokenName() : async Text {
        return nameToken;
    };

    // Retrieve the symbol of the token
    public query func tokenSymbol() : async Text {
        return symbolToken;
    };

    // Function to mint new tokens
    public func mint(owner : Principal, amount : Nat) : async () {
        let defaultAccount = { owner = owner; subaccount = null };
        switch (ledger.get(defaultAccount)) {
            case (null) {
                ledger.put(defaultAccount, amount);
            };
            case (?some) {
                ledger.put(defaultAccount, some + amount);
            };
        };
        return;
    };

    // Transfer tokens between accounts
    public shared ({ caller }) func transfer(from : Account, to : Account, amount : Nat) : async Result<(), Text> {
        let fromBalance = switch (ledger.get(from)) {
            case (null) { 0 };
            case (?some) { some };
        };
        if (fromBalance < amount) {
            return #err("Not enough balance");
        };
        let toBalance = switch (ledger.get(to)) {
            case (null) { 0 };
            case (?some) { some };
        };
        ledger.put(from, fromBalance - amount);
        ledger.put(to, toBalance + amount);
        return #ok();
    };

    // Retrieve the balance of a specific account
    public query func balanceOf(account : Account) : async Nat {
        return switch (ledger.get(account)) {
            case (null) { 0 };
            case (?some) { some };
        };
    };

    // Calculate the total supply of tokens
    public query func totalSupply() : async Nat {
        var total = 0;
        for (balance in ledger.vals()) {
            total += balance;
        };
        return total;
    };

    ///////////////
    // LEVEL #4 //
    /////////////

    // Define the status types for a proposal
    public type Status = {
        #Open;
        #Accepted;
        #Rejected;
    };

    // Define the structure of a proposal
    public type Proposal = {
        id : Nat;
        status : Status;
        manifest : Text;
        votes : Int;
        voters : [Principal];
    };

    // Define the result types for creating a proposal
    public type CreateProposalOk = Nat;
    public type CreateProposalErr = {
        #NotDAOMember;
        #NotEnoughTokens;
    };
    public type createProposalResult = Result<CreateProposalOk, CreateProposalErr>;

    // Define the result types for voting on a proposal
    public type VoteOk = {
        #ProposalAccepted;
        #ProposalRefused;
        #ProposalOpen;
    };
    public type VoteErr = {
        #NotDAOMember;
        #NotEnoughTokens;
        #ProposalNotFound;
        #ProposalEnded;
        #AlreadyVoted;
    };
    public type voteResult = Result<VoteOk, VoteErr>;

    // Variable to keep track of the next proposal ID
    var nextProposalId : Nat = 0;

    // TrieMap to store proposals
    let proposals : TrieMap.TrieMap<Nat, Proposal> = TrieMap.TrieMap(Nat.equal, Hash.hash);

    // Check if a caller is a member of the DAO
    func _isMember(caller : Principal) : Bool {
        switch (dao.get(caller)) {
            case (null) { return false };
            case (?some) { return true };
        };
    };

    // Check if a caller has enough tokens
    func _hasEnoughTokens(caller : Principal, amount : Nat) : Bool {
        let defaultAccount = { owner = caller; subaccount = null };
        switch (ledger.get(defaultAccount)) {
            case (null) { return false };
            case (?some) { return some >= 1000 };
        };
    };

    // Function to burn tokens from an account
    func _burnTokens(caller : Principal, amount : Nat) : () {
        let defaultAccount = { owner = caller; subaccount = null };
        switch (ledger.get(defaultAccount)) {
            case (null) { return };
            case (?some) { ledger.put(defaultAccount, some - amount) };
        };
    };

    // Create a new proposal
    public shared ({ caller }) func createProposal(manifest : Text) : async createProposalResult {
        if (not _isMember(caller)) {
            return #err(#NotDAOMember);
        };
        if (not _hasEnoughTokens(caller, 1)) {
            return #err(#NotEnoughTokens);
        };
        let proposal = {
            id = nextProposalId;
            status = #Open;
            manifest = manifest;
            votes = 0;
            voters = [];
        };
        proposals.put(nextProposalId, proposal);
        nextProposalId += 1;
        _burnTokens(caller, 1);
        return #ok(proposal.id);
    };

    // Retrieve a specific proposal by ID
    public query func getProposal(id : Nat) : async ?Proposal {
        return proposals.get(id);
    };

    // Vote on a proposal
    public shared ({ caller }) func vote(id : Nat, vote : Bool) : async voteResult {
        if (not _isMember(caller)) {
            return #err(#NotDAOMember);
        };
        if (not _hasEnoughTokens(caller, 1)) {
            return #err(#NotEnoughTokens);
        };
        let proposal = switch (proposals.get(id)) {
            case (null) { return #err(#ProposalNotFound) };
            case (?some) { some };
        };
        if (proposal.status != #Open) {
            return #err(#ProposalEnded);
        };
        for (voter in proposal.voters.vals()) {
            if (voter == caller) {
                return #err(#AlreadyVoted);
            };
        };
        let newVoters = Buffer.fromArray<Principal>(proposal.voters);
        newVoters.add(caller);
        let voteChange = if (vote == true) { 1 } else { -1 };
        let newVote = proposal.votes + voteChange;
        let newStatus = if (newVote >= 10) { #Accepted } else if (newVote <= -10) {
            #Rejected;
        } else { #Open };

        let newProposal : Proposal = {
            id = proposal.id;
            status = newStatus;
            manifest = proposal.manifest;
            votes = newVote;
            voters = Buffer.toArray(newVoters);
        };
        proposals.put(id, newProposal);
        _burnTokens(caller, 1);
        if (newStatus == #Accepted) {
            return #ok(#ProposalAccepted);
        };
        if (newStatus == #Rejected) {
            return #ok(#ProposalRefused);
        };
        return #ok(#ProposalOpen);
    };

    ///////////////
    // LEVEL #5 //
    /////////////
    let logo : Text = "<svg xmlns='http://www.w3.org/2000/svg' width='32px' height='32px' viewBox='0 0 32 32'><g fill='none' fill-rule='evenodd'><circle cx='16' cy='16' r='16' fill='#2683FF'/><path fill='#FFF' fill-rule='nonzero' d='M24.977 18.971a1.881 1.881 0 01.673 2.533c-.514.902-1.682 1.222-2.601.718-.09-.049-.168-.107-.248-.165l-4.926 2.784c.012.09.019.181.02.272 0 .107 0 .204-.02.31-.168 1.02-1.147 1.718-2.186 1.553-1.038-.165-1.75-1.126-1.582-2.144L9.15 22.028a3.31 3.31 0 01-.237.155c-.08.039-.159.087-.248.116a1.919 1.919 0 01-2.483-1.038c-.395-.96.08-2.047 1.059-2.435v-5.608a1.225 1.225 0 01-.257-.117 4.16 4.16 0 01-.218-.145 1.86 1.86 0 01-.752-1.738 1.881 1.881 0 011.17-1.499 1.943 1.943 0 011.906.258l5.006-2.843c-.01-.087-.02-.164-.02-.252 0-1.028.88-1.882 1.929-1.882 1.048 0 1.908.834 1.909 1.872 0 .088-.01.165-.02.253l5.045 2.862a1.936 1.936 0 012.82.592c.513.902.177 2.047-.743 2.552-.089.038-.178.087-.267.116v5.618c.079.03.155.065.227.106zm.347 2.348a1.415 1.415 0 00-.505-1.96 1.468 1.468 0 00-1.72.185l-2.266-1.29a2.502 2.502 0 00-.87-3.202 3.679 3.679 0 00-.248-.621l3.423-1.902c.356.33.857.465 1.335.36a1.438 1.438 0 001.098-1.728c-.178-.776-.97-1.251-1.76-1.077a1.438 1.438 0 00-1.099 1.727l-3.462 1.931c-.672-.786-2.809-1.31-2.809-1.31V8.153a1.34 1.34 0 00.91-.892 1.333 1.333 0 00-.91-1.67c-.722-.213-1.484.175-1.702.884a1.333 1.333 0 00.91 1.669v4.366s-1.166.378-1.621.746a3.121 3.121 0 00-1.385.36l-3.255-1.834a1.4 1.4 0 00-.356-1.3 1.465 1.465 0 00-2.057-.068 1.415 1.415 0 00-.07 2.028 1.466 1.466 0 002.058.068l2.938 1.649a2.991 2.991 0 00-.336 3.9l-2.582 1.465a1.49 1.49 0 00-1.345-.349 1.44 1.44 0 00-1.088 1.737c.189.774.981 1.251 1.77 1.066a1.44 1.44 0 001.088-1.736l2.76-1.562c.71.563 1.637.787 2.532.611.276.126.56.233.85.32v4.076a1.557 1.557 0 00-.919.766 1.49 1.49 0 00.683 2.018c.06.03.119.058.188.078.01 0 .02.01.03.01.81.242 1.672-.195 1.919-.99a1.498 1.498 0 00-1.01-1.883V19.69s.742-.068 1.088-.175c.965.38 2.069.155 2.8-.572l2.314 1.33a1.417 1.417 0 00.683 1.562 1.482 1.482 0 001.998-.515zm-17.34-1.358c.22.001.422.115.534.3a.65.65 0 01.079.302.608.608 0 01-.613.601.608.608 0 01-.614-.601c0-.333.275-.602.614-.602zm8.665-13.088a.611.611 0 01-.614.601.608.608 0 01-.613-.601c0-.333.275-.602.613-.602.34 0 .614.27.614.602zm7.478 5.22a.614.614 0 01-.613-.602c0-.332.275-.602.613-.602.34 0 .614.27.614.602a.608.608 0 01-.614.601zM8.27 10.937a.588.588 0 01.228.815.61.61 0 01-.831.223.586.586 0 01-.228-.815.61.61 0 01.831-.223zm16.104 9.14a.588.588 0 01.228.814.639.639 0 01-.535.301.616.616 0 01-.538-.298.592.592 0 010-.607.616.616 0 01.538-.298.66.66 0 01.307.087zm-8.952 5.015a.034.034 0 01.01-.02.608.608 0 01.692-.498.6.6 0 01.515.674.642.642 0 01-.633.514.613.613 0 01-.584-.67zm3.522-9.285a1.429 1.429 0 011.009 1.378c0 .049-.01.098-.01.146-.01.039-.01.078-.02.116v.03c-.02.087-.04.174-.08.261a1.403 1.403 0 01-.543.65c-.06.03-.11.059-.168.088l-.03.01a1.274 1.274 0 01-.366.107l-.05.009c-.069 0-.128.01-.197.01-.323 0-.636-.106-.89-.301l-.268.116c-.082.04-.168.069-.257.088h-.01a2.595 2.595 0 01-1.83-.185h-.01c-.059-.029-.118-.058-.168-.087l-.02-.01c-.059-.038-.108-.077-.168-.116a1.844 1.844 0 01-.761.155c-.08 0-.149 0-.218-.01l-.04-.01-.178-.028-.02-.01a1.339 1.339 0 01-.187-.049 2.141 2.141 0 01-.455-.213 1.725 1.725 0 01-.673-.776c0-.02-.01-.03-.02-.049a.995.995 0 00-.04-.097.468.468 0 01-.03-.068c-.01-.029-.029-.058-.029-.087a.279.279 0 00-.02-.087c-.01-.03-.01-.04-.02-.078-.01-.039-.01-.077-.019-.116 0-.03-.01-.049-.01-.068a1.152 1.152 0 01-.01-.185 1.85 1.85 0 01.01-.223c0-.029.01-.048.01-.068.01-.058.02-.106.03-.155.01-.02.01-.048.02-.068a.94.94 0 01.049-.155c.01-.02.01-.029.02-.048a1.25 1.25 0 01.079-.175l.01-.02a1.977 1.977 0 011.641-1.028c.03-.01.06-.01.1-.01.119 0 .238.01.356.03.05-.06.099-.108.158-.166l.05-.048c.059-.049.108-.097.168-.136l.03-.02c.039-.029.108-.077.138-.097.03-.019.079-.058.109-.068a.466.466 0 00.099-.048c.059-.03.158-.078.217-.097l.05-.039a2.489 2.489 0 011.246-.145h.01c.08.008.159.02.237.038h.01c.08.01.149.04.228.059l.01.01c.079.028.148.057.217.087l.02.01c.068.028.134.06.198.096l.01.01c.059.03.128.078.188.116l.01.01c.069.039.128.087.187.136l.01.01a2.566 2.566 0 01.742 1.038v.01c.02.058.04.126.06.184 0 .02.01.039.01.058.016.05.03.103.039.155l.03.223z'/></g></svg>";

    func _getWebpage() : Text {
        var webpage = "<style>" #
        "body { text-align: center; font-family: Arial, sans-serif; background-color: #f0f8ff; color: #333; }" #
        "h1 { font-size: 3em; margin-bottom: 10px; }" #
        "hr { margin-top: 20px; margin-bottom: 20px; }" #
        "em { font-style: italic; display: block; margin-bottom: 20px; }" #
        "ul { list-style-type: none; padding: 0; }" #
        "li { margin: 10px 0; }" #
        "li:before { content: '👉 '; }" #
        "svg { max-width: 150px; height: auto; display: block; margin: 20px auto; }" #
        "h2 { text-decoration: underline; }" #
        "</style>";

        webpage := webpage # "<div><h1>" # name # "</h1></div>";
        webpage := webpage # "<em>" # manifesto # "</em>";
        webpage := webpage # "<div>" # logo # "</div>";
        webpage := webpage # "<hr>";
        webpage := webpage # "<h2>Our goals:</h2>";
        webpage := webpage # "<ul>";
        for (goal in goals.vals()) {
            webpage := webpage # "<li>" # goal # "</li>";
        };
        webpage := webpage # "</ul>";
        return webpage;
    };

    public type DAOStats = {
        name : Text;
        manifesto : Text;
        goals : [Text];
        member : [Text];
        logo : Text;
        numberOfMembers : Nat;
    };
    
    // public type HttpRequest = Http.Request;
    // public type HttpResponse = Http.Response;

    // public func http_request(request : HttpRequest) : async HttpResponse {
    //     return ({
    //         status_code = 404;
    //         headers = [];
    //         body = Blob.fromArray([]);
    //         streaming_strategy = null;
    //     });
    // };

    public query func getStats() : async DAOStats {
        return ({
            name = "";
            manifesto = "";
            goals = [];
            member = [];
            logo = "";
            numberOfMembers = 0;
        });
    };
};