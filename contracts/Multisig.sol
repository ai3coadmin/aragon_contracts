pragma solidity 0.8.17;

import {Multisig} from "@aragon/osx/plugins/governance/multisig/Multisig.sol";

contract VetoMultisig is Multisig {

    /// @notice An tax amount which would be setted by Governance Dao
    uint256 tax = 0;

    bytes4 public constant MULTISIG_INTERFACE_ID_CHECK =
    this.initialize.selector ^
    this.updateMultisigSettings.selector ^
    this.createProposal.selector ^
    this.getProposal.selector;
    /// @notice Permissions
    bytes32 public constant VETO_PERMISSION_ID = keccak256("VETO_PERMISSION");
    bytes32 public constant TAX_PERMISSION_ID = keccak256("TAX_PERMISSION");

    event TaxChanged(
        uint256 newTax,
        uint256 oldTax
    );

    error ZeroAmount();

    event CancelVote(uint256 _proposalId);

    /// @notice Emitted when a token deposit has been made to the DAO.
    /// @param sender The address of the sender.
    /// @param token The address of the deposited token.
    /// @param amount The amount of tokens deposited.
    /// @param _reference The reference describing the deposit reason.
    event Deposited(
        address indexed sender,
        address indexed token,
        uint256 amount,
        string _reference
    );


    function cancelVote(uint256 _proposalId) external auth(VETO_PERMISSION_ID) returns (uint256) {
        // create a modifier here checking whether the proposal is still active, otherwise cancelling would make no point and transaction should be reverted
        Proposal storage proposal = proposals[_proposalId];
        proposal = proposals[_proposalId]; // `proposals` would be your mapping of proposals

        require(
            proposal.parameters.endDate >= uint64(block.timestamp),
            "Impossible to cancel already voted!"
        );

        emit CancelVote(_proposalId);
        proposal.parameters.endDate = uint64(block.timestamp);

        return _proposalId;
    }


    function deposit(
        uint256 _amount,
        string calldata _reference
    ) external payable {
        uint256 taxAmount = 0;
        if (_amount == 0) revert ZeroAmount();
        if (tax != 0) {
            taxAmount = _amount * tax / 100;
        }
        // TODO: Let us know what to do here
//        emit Deposited(msg.sender, address(votingToken), _amount, _reference);
    }

    /// @notice Change the Tax percentage by Governance Dao
    function changeTax(uint256 _tax) external auth(TAX_PERMISSION_ID)  {
        emit TaxChanged(_tax, tax);
        tax = _tax;
    }
}
